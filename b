// This is now a Next.js page component placed in `app/page.tsx` or `pages/index.tsx`
"use client";

import { useState, useEffect } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AlertTriangle } from "lucide-react";
import CryptoJS from "crypto-js";

const generateSeedPhrase = () => {
  const words = [
    "apple", "banana", "cat", "dog", "echo", "falcon", "grape", "hat", "ice", "jungle", "kite", "lemon",
    "moon", "nest", "owl", "peach", "queen", "river", "sun", "tree", "umbrella", "van", "wolf", "xray", "yarn", "zebra"
  ];
  return Array.from({ length: 6 }, () => words[Math.floor(Math.random() * words.length)]);
};

const encrypt = (data, key) => CryptoJS.AES.encrypt(JSON.stringify(data), key).toString();
const decrypt = (ciphertext, key) => {
  try {
    const bytes = CryptoJS.AES.decrypt(ciphertext, key);
    return JSON.parse(bytes.toString(CryptoJS.enc.Utf8));
  } catch (e) {
    return null;
  }
};

const LOCAL_STORAGE_KEY = "proxy_users";

export default function Home() {
  const [users, setUsers] = useState({});
  const [loggedIn, setLoggedIn] = useState(false);
  const [registerMode, setRegisterMode] = useState(false);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [hovered, setHovered] = useState(null);
  const [seedPhrase, setSeedPhrase] = useState<string[]>([]);
  const [recoveryMode, setRecoveryMode] = useState(false);
  const [recoveryInput, setRecoveryInput] = useState("");

  useEffect(() => {
    const data = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (data) {
      const decrypted = decrypt(data, "secret-key");
      if (decrypted) setUsers(decrypted);
    }
  }, []);

  const saveUsers = (data) => {
    setUsers(data);
    localStorage.setItem(LOCAL_STORAGE_KEY, encrypt(data, "secret-key"));
  };

  const handleLogin = () => {
    const user = users[username];
    if (user && user.password === password) {
      setLoggedIn(true);
      setError("");
    } else {
      setError("Invalid username or password");
    }
  };

  const handleRegister = () => {
    if (users[username]) {
      setError("Username already exists");
      return;
    }
    const newSeed = generateSeedPhrase();
    const newUsers = {
      ...users,
      [username]: { password, seedPhrase: newSeed }
    };
    saveUsers(newUsers);
    setSeedPhrase(newSeed);
    setError("");
  };

  const handleRecovery = () => {
    const match = Object.entries(users).find(([, user]) => user.seedPhrase.join(" ") === recoveryInput.trim());
    if (match) {
      setUsername(match[0]);
      setPassword(match[1].password);
      setError("Recovered account. Please log in.");
    } else {
      setError("Invalid recovery phrase");
    }
  };

  const protectedLinks = ["Dashboard", "Residential Proxies", "Static ISP Proxies"];

  if (!loggedIn) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#101827] text-white">
        <Card className="w-full max-w-sm bg-[#1E293B] border-none">
          <CardContent className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-center">
              {recoveryMode ? "Recover Account" : registerMode ? "Register" : "Login"}
            </h2>
            {!recoveryMode && (
              <>
                <Input
                  placeholder="Username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="mb-3 bg-[#334155] text-white border-none"
                />
                <Input
                  type="password"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="mb-3 bg-[#334155] text-white border-none"
                />
              </>
            )}
            {recoveryMode && (
              <Input
                placeholder="Enter your recovery phrase"
                value={recoveryInput}
                onChange={(e) => setRecoveryInput(e.target.value)}
                className="mb-3 bg-[#334155] text-white border-none"
              />
            )}
            {error && <p className="text-red-400 text-sm mb-2">{error}</p>}
            {registerMode && seedPhrase.length > 0 && (
              <div className="text-sm bg-[#334155] text-white p-2 rounded mb-2">
                <p className="font-bold">Save these recovery words:</p>
                <p>{seedPhrase.join(" ")}</p>
              </div>
            )}
            <Button
              onClick={recoveryMode ? handleRecovery : registerMode ? handleRegister : handleLogin}
              className="w-full bg-[#0EA5E9] hover:bg-[#0284C7] text-white"
            >
              {recoveryMode ? "Recover" : registerMode ? "Register" : "Login"}
            </Button>
            <div className="text-center text-sm text-blue-400 cursor-pointer mt-2 space-y-1">
              {!recoveryMode && (
                <p onClick={() => { setRegisterMode(!registerMode); setSeedPhrase([]); setError(""); }}>
                  {registerMode ? "Already have an account? Login" : "Don't have an account? Register"}
                </p>
              )}
              <p onClick={() => { setRecoveryMode(!recoveryMode); setError(""); }}>
                {recoveryMode ? "Back to login" : "Recover account"}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-[#0F172A] text-white">
      <div className="w-64 bg-[#1E293B] p-4 space-y-4">
        {protectedLinks.map((link, index) => (
          <div
            key={index}
            onMouseEnter={() => setHovered(index)}
            onMouseLeave={() => setHovered(null)}
            className="relative group cursor-not-allowed"
          >
            <div className="p-2 rounded hover:bg-[#334155] transition">
              {link}
            </div>
            {hovered === index && (
              <div className="absolute left-full ml-2 top-0 bg-white text-black p-2 rounded shadow text-sm flex items-center space-x-2 z-10">
                <AlertTriangle className="text-red-600 w-4 h-4" />
                <span>u cannot access this without a membership</span>
              </div>
            )}
          </div>
        ))}
        <Button className="bg-[#0EA5E9] hover:bg-[#0284C7] text-white mt-4">+ Add Funds</Button>
      </div>

      <div className="flex-1 p-6">
        <h1 className="text-2xl font-bold mb-6">Welcome back, {username.charAt(0).toUpperCase() + username.slice(1)}</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <Card className="bg-[#1E293B] border-none">
            <CardContent className="p-4">
              <h3 className="font-semibold">Starter Residential</h3>
              <p className="text-sm">0.00 GB data remaining</p>
              <p className="text-xs text-green-400">93% Success Rate</p>
              <Button size="sm" className="mt-2 bg-[#0EA5E9] hover:bg-[#0284C7] text-white">Add data</Button>
            </CardContent>
          </Card>
          <Card className="bg-[#1E293B] border-none">
            <CardContent className="p-4">
              <h3 className="font-semibold">Elite Residential</h3>
              <p className="text-sm">0.00 GB data remaining</p>
              <p className="text-xs text-green-400">99.9% Success Rate</p>
              <Button size="sm" className="mt-2 bg-[#0EA5E9] hover:bg-[#0284C7] text-white">Add data</Button>
            </CardContent>
          </Card>
          <Card className="bg-[#1E293B] border-none">
            <CardContent className="p-4">
              <h3 className="font-semibold">Static ISP Proxies</h3>
              <p className="text-sm text-gray-400">No Static Residential Proxies yet!</p>
              <Button size="sm" className="mt-2 bg-[#0EA5E9] hover:bg-[#0284C7] text-white">Buy proxies</Button>
            </CardContent>
          </Card>
        </div>
        <div className="mt-6">
          <Card className="bg-[#1E293B] border-none">
            <CardContent className="p-4">
              <h3 className="font-semibold">Referral Program</h3>
              <p className="text-sm">Earn 20% commission on all your referral's purchases!</p>
              <Button size="sm" variant="outline" className="mt-2 border-white text-white">Coming soon</Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
