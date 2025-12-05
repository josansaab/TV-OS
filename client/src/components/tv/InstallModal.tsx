import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Terminal, Copy, Check, X, HardDrive } from 'lucide-react';

interface InstallModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function InstallModal({ isOpen, onClose }: InstallModalProps) {
  const [step, setStep] = useState(0);
  const [copied, setCopied] = useState(false);

  const installCommand = 'curl -sL https://nexus-os.tv/install.sh | sudo bash';

  useEffect(() => {
    if (isOpen) {
      setStep(0);
      const timer1 = setTimeout(() => setStep(1), 1000);
      const timer2 = setTimeout(() => setStep(2), 2500);
      const timer3 = setTimeout(() => setStep(3), 4500);
      return () => {
        clearTimeout(timer1);
        clearTimeout(timer2);
        clearTimeout(timer3);
      };
    }
  }, [isOpen]);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(installCommand);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50"
            onClick={onClose}
            data-testid="modal-backdrop"
          />
          <div className="fixed inset-0 flex items-center justify-center z-50 pointer-events-none">
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-[#1a1b26] border border-white/10 p-8 rounded-2xl w-[650px] shadow-2xl pointer-events-auto font-mono"
              data-testid="install-modal"
            >
              <div className="flex items-center gap-3 mb-6 border-b border-white/10 pb-4">
                <Terminal className="w-6 h-6 text-primary" />
                <h2 className="text-xl text-white font-bold">Install Nexus TV OS on Ubuntu</h2>
                <button 
                  onClick={onClose} 
                  className="ml-auto text-white/50 hover:text-white transition-colors"
                  data-testid="button-close-modal"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-4">
                <div className="flex items-center gap-3 bg-black/50 rounded-lg p-3">
                  <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                  <code className="text-green-400 text-sm flex-1 overflow-x-auto">{installCommand}</code>
                  <button 
                    onClick={handleCopy}
                    className="p-2 hover:bg-white/10 rounded-lg transition-colors text-white/60 hover:text-white"
                    data-testid="button-copy-command"
                  >
                    {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
                  </button>
                </div>

                <div className="bg-black/50 rounded-lg p-4 h-52 overflow-y-auto text-xs font-mono space-y-2 text-green-400/80">
                  <p>&gt; Initializing installer...</p>
                  {step >= 1 && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-1">
                      <p>&gt; Detected Ubuntu 24.03 LTS</p>
                      <p>&gt; Verifying hardware compatibility... <span className="text-green-400">OK</span></p>
                      <p>&gt; Downloading core packages...</p>
                    </motion.div>
                  )}
                  {step >= 2 && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-1">
                      <p>&gt; Installing Plex Media Server... <span className="text-green-400">Done</span></p>
                      <p>&gt; Installing Kodi... <span className="text-green-400">Done</span></p>
                      <p>&gt; Installing Netflix web app... <span className="text-green-400">Done</span></p>
                      <p>&gt; Installing FreeTube... <span className="text-green-400">Done</span></p>
                      <p>&gt; Configuring graphical interface...</p>
                      <p>&gt; Setting up auto-login and kiosk mode...</p>
                    </motion.div>
                  )}
                  {step >= 3 && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-1 mt-2">
                      <p className="text-white font-bold">&gt; ================================</p>
                      <p className="text-white font-bold">&gt; INSTALLATION COMPLETE!</p>
                      <p className="text-white font-bold">&gt; ================================</p>
                      <p className="text-white">&gt; Nexus TV OS is ready.</p>
                      <p className="text-white">&gt; Reboot your system to start in TV mode.</p>
                    </motion.div>
                  )}
                </div>

                <div className="flex gap-3 mt-4">
                  {step === 3 ? (
                    <motion.button
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      className="flex-1 py-3 bg-primary text-white rounded-lg font-bold flex items-center justify-center gap-2"
                      onClick={onClose}
                      data-testid="button-reboot"
                    >
                      <HardDrive className="w-4 h-4" />
                      Reboot System
                    </motion.button>
                  ) : (
                    <div className="flex-1 py-3 bg-white/5 text-white/50 rounded-lg font-bold flex items-center justify-center gap-2">
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Installing...
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
