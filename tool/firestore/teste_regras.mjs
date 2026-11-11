import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, addDoc, orderBy, limit, collection, query, where, getCountFromServer, getDocs, serverTimestamp, runTransaction } from 'firebase/firestore';

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
// --- O ranking ---
const semana = Math.floor((Math.floor(Date.now() / 86400000) + 3) / 7);
const linha = (pontos, extra = {}) => ({ nome: 'Ana Paula', pontos, chapeu: 'helmet', pelagem: 'caramelo', embaixador: false, em: serverTimestamp(), ...extra });
const R = (d, quadro, uid) => doc(d, `rankings/${quadro}/jogadores/${uid}`);
await ok('Ana entra no ranking da Torre', setDoc(R(A, 'torre_geral', 'ana'), linha(12)));
await ok('Ana entra no ranking da semana', setDoc(R(A, `torre_s${semana}`, 'ana'), linha(12)));
await nao('Ana escreve na semana passada', setDoc(R(A, `torre_s${semana - 1}`, 'ana'), linha(12)));
await nao('Ana escreve na semana que vem', setDoc(R(A, `torre_s${semana + 1}`, 'ana'), linha(12)));
await nao('placar que não existe', setDoc(R(A, 'xadrez_geral', 'ana'), linha(12)));
await nao('Caio escreve a linha da Ana', setDoc(R(C, 'torre_geral', 'ana'), linha(99)));
await nao('pontuação acima do teto da Torre', setDoc(R(B, 'torre_geral', 'bia'), linha(501)));
await ok('o teto do Infinito é outro', setDoc(R(B, 'infinito_geral', 'bia'), linha(40000)));
await nao('pontuação zero', setDoc(R(C, 'torre_geral', 'caio'), linha(0)));
await nao('pontuação que não é número inteiro', setDoc(R(C, 'torre_geral', 'caio'), linha('muitos')));
await nao('nome curto', setDoc(R(C, 'torre_geral', 'caio'), linha(5, { nome: 'Zé' })));
await nao('nome comprido', setDoc(R(C, 'torre_geral', 'caio'), linha(5, { nome: 'a'.repeat(17) })));
await nao('nome com símbolos', setDoc(R(C, 'torre_geral', 'caio'), linha(5, { nome: '<b>Caio</b>' })));
await ok('nome com acento, número e _', setDoc(R(C, 'torre_geral', 'caio'), linha(5, { nome: 'João_2014' })));
await nao('campo a mais', setDoc(R(C, 'blitz_geral', 'caio'), linha(5, { admin: true })));
await nao('sem a hora do servidor', setDoc(R(C, 'blitz_geral', 'caio'), linha(5, { em: new Date(2020, 0, 1) })));
await ok('Ana bate o próprio recorde', setDoc(R(A, 'torre_geral', 'ana'), linha(20)));
await nao('a pontuação da Ana não diminui', setDoc(R(A, 'torre_geral', 'ana'), linha(3)));
await ok('Ana troca de nome sem perder pontos', setDoc(R(A, 'torre_geral', 'ana'), linha(20, { nome: 'Aninha' })));
await ok('Bia vê o topo', getDocs(query(collection(B, 'rankings/torre_geral/jogadores'), orderBy('pontos', 'desc'), limit(20))).then((r) => { if (r.docs[0].id !== 'ana') throw new Error('primeiro: ' + r.docs[0].id); }));
await ok('Caio conta quem está acima dele', getCountFromServer(query(collection(C, 'rankings/torre_geral/jogadores'), where('pontos', '>', 5))).then((r) => { if (r.data().count !== 1) throw new Error('contagem ' + r.data().count); }));
await nao('sem login não lê o ranking', getDocs(collection(env.unauthenticatedContext().firestore(), 'rankings/torre_geral/jogadores')));
await nao('Caio apaga a linha da Ana', deleteDoc(R(C, 'torre_geral', 'ana')));
await ok('Caio apaga a própria linha', deleteDoc(R(C, 'torre_geral', 'caio')));
const denuncia = (por) => ({ quadro: 'torre_geral', uid: 'ana', nome: 'Aninha', por, em: serverTimestamp() });
await ok('Bia denuncia um nome', addDoc(collection(B, 'denuncias'), denuncia('bia')));
await nao('denúncia em nome de outro', addDoc(collection(B, 'denuncias'), denuncia('caio')));
await nao('ninguém lê as denúncias', getDocs(collection(A, 'denuncias')));
await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'config/ranking'), { ocultos: ['x'], palavras: ['zureta'] }));
await ok('o jogo lê a moderação', getDoc(doc(A, 'config/ranking')));
await nao('jogador não mexe na moderação', setDoc(doc(A, 'config/ranking'), { ocultos: [] }));
await env.cleanup();
