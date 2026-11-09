import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { doc, setDoc, getDoc, updateDoc, collection, query, where, getCountFromServer, getDocs, serverTimestamp, runTransaction } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-capiblocks',
  firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
});
const db = (uid) => env.authenticatedContext(uid).firestore();
const ok = async (n, p) => { try { await assertSucceeds(p); console.log('OK   ', n); } catch (e) { console.log('FALHA', n, e.message); process.exitCode = 1; } };
const nao = async (n, p) => { try { await assertFails(p); console.log('OK   ', n, '(recusado)'); } catch (e) { console.log('FALHA', n, 'deveria recusar'); process.exitCode = 1; } };

const A = db('ana'), B = db('bia'), C = db('caio');
// Ana registers her code (transaction, like the app).
await ok('Ana cria o código', runTransaction(A, async (t) => {
  const r = doc(A, 'codigos/ABC234'); const s = await t.get(r);
  if (!s.exists()) t.set(r, { uid: 'ana', criadoEm: serverTimestamp() });
}));
await nao('Bia toma o código da Ana', setDoc(doc(B, 'codigos/ABC234'), { uid: 'bia' }));
await nao('código inválido', setDoc(doc(B, 'codigos/ABC230'), { uid: 'bia' }));
await ok('Bia lê de quem é o código', getDoc(doc(B, 'codigos/ABC234')));
await ok('Bia entra pelo convite da Ana', setDoc(doc(B, 'convites/bia'), { codigo: 'ABC234', dono: 'ana', fase5: false, criadoEm: serverTimestamp() }));
await nao('Caio finge que o convite é dele', setDoc(doc(C, 'convites/caio'), { codigo: 'ABC234', dono: 'caio', fase5: false }));
await nao('Caio cria o convite no lugar da Bia', setDoc(doc(C, 'convites/xx'), { codigo: 'ABC234', dono: 'ana', fase5: false }));
await nao('Caio já com fase 5', setDoc(doc(C, 'convites/caio'), { codigo: 'ABC234', dono: 'ana', fase5: true }));
await nao('Ana com o próprio código', setDoc(doc(A, 'convites/ana'), { codigo: 'ABC234', dono: 'ana', fase5: false }));
await ok('Bia marca a fase 5', updateDoc(doc(B, 'convites/bia'), { fase5: true }));
await nao('Bia muda o código depois', updateDoc(doc(B, 'convites/bia'), { codigo: 'XYZ789' }));
await nao('Caio marca a fase 5 da Bia', updateDoc(doc(C, 'convites/bia'), { fase5: true }));
const q = (d, uid) => query(collection(d, 'convites'), where('dono', '==', uid), where('fase5', '==', true));
await ok('Ana conta os amigos dela', getCountFromServer(q(A, 'ana')).then((r) => { if (r.data().count !== 1) throw new Error('contagem ' + r.data().count); }));
await nao('Caio conta os amigos da Ana', getCountFromServer(q(C, 'ana')));
await nao('Caio lista tudo', getDocs(collection(C, 'convites')));
await nao('sem login', getDoc(doc(env.unauthenticatedContext().firestore(), 'codigos/ABC234')));
await env.cleanup();
