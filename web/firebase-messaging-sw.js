importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyBgwzTp5qH-iSVU3XK9tqGXt2DnjllDRes",
  authDomain: "webnox-sprintly-55789.firebaseapp.com",
  projectId: "webnox-sprintly-55789",
  storageBucket: "webnox-sprintly-55789.firebasestorage.app",
  messagingSenderId: "246504429530",
  appId: "1:246504429530:web:1afc90a5d1a2ce69e212e3",
  measurementId: "G-FFBRSN0BMR"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here if needed
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
