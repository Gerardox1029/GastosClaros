const { parseYapeText } = require('../lib/yape-parser');
const { periodRange } = require('../lib/financial-context');

test.each(['1,250.50', '1.250,50', '1250.50', '1250,50'])( 'reads amount %s and Peru date', (amount) => {
  const result = parseYapeText(`¡Yapeaste!\nS/ ${amount}\nJuan Pérez\n15 oct. 2026 - 02:30 p. m.\nMensaje: Almuerzo`);
  expect(result).toEqual({ monto: 1250.5, nombre: 'Juan Pérez', descripcion: 'Almuerzo', fecha: '2026-10-15T19:30:00.000Z' });
});
test('rejects phone numbers as amounts but tolerates unreadable dates', () => {
  expect(() => parseYapeText('Celular 999123456\n15/10/2026')).toThrow('monto');
  expect(parseYapeText('S/ 10.00\nJuan Pérez\n31/02/2026')).toMatchObject({ monto: 10, nombre: 'Juan Pérez', fecha: null });
});

test('keeps amount and name when optional fields are missing', () => {
  expect(parseYapeText('¡Te Yapearon!\nS/70\nMayra Ram*')).toEqual({
    monto: 70, nombre: 'Mayra Ram*', descripcion: '', fecha: null,
  });
});

test('uses receipt time instead of the phone status-bar time', () => {
  expect(parseYapeText('Claro 10:17\n¡Te Yapearon!\nS/70\nMayra Ram*\n26 oct. 2026 | 06:21 a. m.\nCÓDIGO DE SEGURIDAD 945'))
    .toMatchObject({ monto: 70, nombre: 'Mayra Ram*', descripcion: '', fecha: '2026-10-26T11:21:00.000Z' });
});
test('daily range follows Peru midnight even when UTC is the next day', () => {
  expect(periodRange('1D', new Date('2026-10-17T02:00:00Z'))).toEqual({
    start: new Date('2026-10-16T05:00:00Z'), end: new Date('2026-10-17T05:00:00Z'),
  });
});

test('reads Yape layout with a large integer amount and an unlabeled note', () => {
  const result = parseYapeText('¡Yapeaste!\nS/75\nPersona Prue*\n15 oct. 2026 | (9) 11:21 a.m.\nEJ Mensaje de prueba\nCÓDIGO DE SEGURIDAD 3 2 4\nDATOS DE LA TRANSACCIÓN\nNro. de operación 12345678');
  expect(result).toEqual({ monto: 75, nombre: 'Persona Prue*', descripcion: 'Mensaje de prueba',
    fecha: '2026-10-15T16:21:00.000Z', operationId: '12345678' });
});
