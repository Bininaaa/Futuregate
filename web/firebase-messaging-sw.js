importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDcQlwKznxxnom_W5nIhC4uT1HyxSAOqHk",
  appId: "1:620923930909:web:5583407a1c39bdcae9f9f4",
  messagingSenderId: "620923930909",
  projectId: "avenirdz-7305d",
  authDomain: "avenirdz-7305d.firebaseapp.com",
  storageBucket: "avenirdz-7305d.firebasestorage.app",
  measurementId: "G-82DGL6RKGW",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || "New message";
  const options = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
  };
  return self.registration.showNotification(title, options);
});
