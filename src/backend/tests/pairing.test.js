import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Pairing Logic', () => {
  it('should generate 6-digit pairing codes', () => {
    const generatePairingCode = () => {
      return Math.floor(100000 + Math.random() * 900000).toString();
    };
    
    const code = generatePairingCode();
    assert.strictEqual(code.length, 6);
    assert.strictEqual(typeof parseInt(code), 'number');
    assert(parseInt(code) >= 100000);
    assert(parseInt(code) <= 999999);
  });
  
  it('should validate pairing code format', () => {
    const isValidPairingCode = (code) => {
      return /^\d{6}$/.test(code);
    };
    
    assert(isValidPairingCode('123456'));
    assert(!isValidPairingCode('12345'));
    assert(!isValidPairingCode('1234567'));
    assert(!isValidPairingCode('abcdef'));
  });
});