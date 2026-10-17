const { parseYapeText } = require('../lib/yape-parser');
const { periodRange } = require('../lib/financial-context');

test.each(['1,250.50', '1.250,50', '1250.50', '1250,50'])( 'reads amount %s and Peru date', (amount) => {
  const result = parseYapeText(`¡Yapeaste!\nS/ ${amount}\nJuan Pérez\n15 oct. 2026 - 02:30 p. m.\nMensaje: Almuerzo`);
  expect(result).toEqual({ monto: 1250.5, nombre: 'Juan Pérez', descripcion: 'Almuerzo', fecha: '2026-10-15T19:30:00.000Z' });
});
test('rejects phone numbers as amounts and invalid calendar dates', () => {
  expect(() => parseYapeText('Celular 999123456\n15/10/2026')).toThrow('monto');
  expect(() => parseYapeText('S/ 10.00\n31/02/2026')).toThrow('fecha');
});
test('daily range follows Peru midnight even when UTC is the next day', () => {
  expect(periodRange('1D', new Date('2026-10-17T02:00:00Z'))).toEqual({
    start: new Date('2026-10-16T05:00:00Z'), end: new Date('2026-10-17T05:00:00Z'),
  });
});
