// config.js - Edit this file with your own endpoints
const CONFIG = {
    // Proxmox (you can add multiple nodes)
    proxmox: [
        {
            name: "pve-node1",
            url: "https://192.168.1.10:8006",
            username: "root@pam",
            password: "YOUR_PASSWORD_HERE",   // ← Change this
            token: null                       // or use API token (recommended)
        }
        // Add more nodes here if needed
    ],

    // Docker hosts (support for multiple)
    docker: [
        {
            name: "Main Docker Host",
            url: "http://localhost:2375"     // Enable Docker HTTP API or use unix socket
        }
        // You can add remote Docker hosts too
    ],

    // Jellyfin
    jellyfin: {
        url: "http://192.168.1.50:8096",
        apiKey: "YOUR_JELLYFIN_API_KEY_HERE"
    },

    // Tailscale (optional)
    tailscale: {
        enabled: true,
        statusUrl: "http://localhost:8080/api/status"   // You can run a small Tailscale status helper if needed
    }
};
