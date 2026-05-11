// config.js - Personal configuration for homelab-dashboard.html
// Edit this file with your own data. Never commit real passwords/tokens to GitHub.

const CONFIG = {
    // ==================== Proxmox ====================
    proxmox: [
        {
            name: "pve-node1",
            url: "https://192.168.1.10:8006",      // Change to your Proxmox IP
            username: "root@pam",
            password: "YOUR_PROXMOX_PASSWORD_HERE", // Recommended: Use API Token instead
            // token: "root@pam!tokenname=xxxxxxxxxxxxxxxx"   // Better security option
        }
        // Add more Proxmox nodes here if you have them
    ],

    // ==================== Docker ====================
    docker: [
        {
            name: "Main Docker Host",
            url: "http://localhost:2375"           // Enable Docker HTTP API on port 2375
            // For remote hosts: "http://192.168.1.XX:2375"
        }
        // You can add more Docker hosts (e.g. separate Jellyfin server)
    ],

    // ==================== Jellyfin ====================
    jellyfin: {
        url: "http://192.168.1.50:8096",           // Change to your Jellyfin URL
        apiKey: "YOUR_JELLYFIN_API_KEY_HERE"
    },

    // ==================== Tailscale ====================
    tailscale: {
        enabled: true,
        // Optional: You can run a small local service to expose Tailscale status
        statusUrl: "http://localhost:8080/api/tailscale"   
    },

    // Refresh interval in milliseconds (30 seconds default)
    refreshInterval: 30000
};
