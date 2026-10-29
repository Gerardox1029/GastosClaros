(function () {
  'use strict';

  let installEvent = null;
  let sessionToken = null;

  try { sessionToken = localStorage.getItem('gastosclaros.session'); } catch (_) {}

  function publicKeyBytes(value) {
    const padded = value + '='.repeat((4 - value.length % 4) % 4);
    const binary = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
    return Uint8Array.from(binary, (char) => char.charCodeAt(0));
  }

  async function syncPush() {
    if (!sessionToken || !('PushManager' in window) || !('Notification' in window) ||
        Notification.permission !== 'granted' || !('serviceWorker' in navigator)) return false;
    try {
      const configResponse = await fetch('/api/push-config', {
        headers: { Authorization: `Bearer ${sessionToken}` }, cache: 'no-store'
      });
      if (!configResponse.ok) return false;
      const config = await configResponse.json();
      if (!config.available || !config.publicKey) return false;
      const registration = await navigator.serviceWorker.ready;
      let subscription = await registration.pushManager.getSubscription();
      if (!subscription) subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: publicKeyBytes(config.publicKey)
      });
      const response = await fetch('/api/push-subscription', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${sessionToken}` },
        body: JSON.stringify({ subscription: subscription.toJSON() })
      });
      return response.ok;
    } catch (error) {
      console.warn('No se pudo activar Web Push:', error);
      return false;
    }
  }

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    installEvent = event;
  });
  window.addEventListener('appinstalled', () => {
    installEvent = null;
  });

  if ('serviceWorker' in navigator && window.isSecureContext) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/sw.js').catch((error) => {
        console.warn('No se pudo registrar el service worker:', error);
      });
    });
  }

  function installed() {
    return window.matchMedia('(display-mode: standalone)').matches ||
      navigator.standalone === true;
  }

  window.gastosClarosPwa = {
    getToken() { return sessionToken; },

    setToken(token) {
      sessionToken = token;
      try { localStorage.setItem('gastosclaros.session', token); } catch (_) {}
      void syncPush();
    },

    async clearToken() {
      try {
        if (sessionToken && 'serviceWorker' in navigator) {
          const registration = await navigator.serviceWorker.getRegistration('/');
          if (!registration) throw new Error('No service worker');
          const subscription = await registration.pushManager?.getSubscription();
          if (subscription) {
            await fetch('/api/push-subscription', {
              method: 'DELETE',
              headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${sessionToken}` },
              body: JSON.stringify({ subscription: subscription.toJSON() })
            });
            await subscription.unsubscribe();
          }
        }
      } catch (_) {}
      sessionToken = null;
      try { localStorage.removeItem('gastosclaros.session'); } catch (_) {}
    },

    syncPush,

    async install() {
      if (installed()) return 'GastosClaros ya está instalada. Ábrela desde el icono de tu dispositivo.';
      if (installEvent) {
        const event = installEvent;
        installEvent = null;
        await event.prompt();
        const choice = await event.userChoice;
        return choice.outcome === 'accepted'
          ? 'Instalación iniciada. Busca GastosClaros en tu pantalla de inicio.'
          : 'Puedes instalar GastosClaros cuando quieras desde este menú.';
      }
      if (/iPad|iPhone|iPod/.test(navigator.userAgent)) {
        return 'En Safari, toca Compartir y luego Añadir a pantalla de inicio.';
      }
      return 'Abre el menú del navegador y elige Instalar app o Añadir a pantalla de inicio.';
    },

    notificationPermission() {
      return 'Notification' in window ? Notification.permission : 'unsupported';
    },

    async requestNotifications() {
      if (!('Notification' in window) || !('serviceWorker' in navigator) || !window.isSecureContext) {
        return 'unsupported';
      }
      const permission = Notification.permission === 'default'
        ? await Notification.requestPermission() : Notification.permission;
      if (permission !== 'granted') return permission;
      return await syncPush() ? 'granted' : 'push-unavailable';
    },

    async notifySaved(type, amount, description) {
      if (!('Notification' in window) || Notification.permission !== 'granted' ||
          !('serviceWorker' in navigator)) return false;
      try {
        const registration = await navigator.serviceWorker.ready;
        if (await registration.pushManager?.getSubscription()) return false;
        const isIncome = type === 'ingreso';
        const sign = isIncome ? '+' : '−';
        const shortDescription = String(description || '').trim().replace(/\s+/g, ' ').slice(0, 70);
        const money = new Intl.NumberFormat('es-PE', {
          minimumFractionDigits: 2, maximumFractionDigits: 2
        }).format(amount);
        await registration.showNotification(
          `${sign} S/ ${money} · ${shortDescription}`, {
            body: isIncome ? 'Saldo registrado' : 'Gasto registrado',
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            tag: `registro-${Date.now()}`,
            data: { url: isIncome ? '/?tab=saldo' : '/?tab=gastos' }
          }
        );
        return true;
      } catch (error) {
        console.warn('No se pudo mostrar la notificación:', error);
        return false;
      }
    }
  };
})();
