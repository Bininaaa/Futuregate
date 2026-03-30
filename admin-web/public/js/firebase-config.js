import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getAuth, signInWithEmailAndPassword, signOut, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { getFirestore, collection, collectionGroup, doc, getDocs, getDoc, setDoc, updateDoc, deleteDoc, query, orderBy, limit, where, writeBatch, serverTimestamp, startAfter, onSnapshot, getCountFromServer } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyDcQlwKznxxnom_W5nIhC4uT1HyxSAOqHk",
  authDomain: "avenirdz-7305d.firebaseapp.com",
  projectId: "avenirdz-7305d",
  storageBucket: "avenirdz-7305d.firebasestorage.app",
  messagingSenderId: "620923930909",
  appId: "1:620923930909:web:5583407a1c39bdcae9f9f4",
  measurementId: "G-82DGL6RKGW"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

export { auth, db, signInWithEmailAndPassword, signOut, onAuthStateChanged, collection, collectionGroup, doc, getDocs, getDoc, setDoc, updateDoc, deleteDoc, query, orderBy, limit, where, writeBatch, serverTimestamp, startAfter, onSnapshot, getCountFromServer };
