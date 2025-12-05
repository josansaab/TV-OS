import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Terminal, Check, X, HardDrive } from 'lucide-react';
import { cn } from '@/lib/utils';

interface InstallModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function InstallModal({ isOpen, onClose }: InstallModalProps) {
  const [step, setStep] = React.useState(0);

  React.useEffect(() => {
    if (isOpen && step === 0) {
      const timer = setTimeout(() => setStep(1), 1000);
      const timer2 = setTimeout(() => setStep(2), 2500);
      const timer3 = setTimeout(() => setStep(3), 4500);
      return () => {
        clearTimeout(timer);
        clearTimeout(timer2);
        clearTimeout(timer3);
      };
    }
    if (!isOpen) {
      setStep(0);
    }
  }, [isOpen]);

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
          />
          <div className="fixed inset-0 flex items-center justify-center z-50 pointer-events-none">
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-[#1a1b26] border border-white/10 p-8 rounded-2xl w-[600px] shadow-2xl pointer-events-auto font-mono"
            >
              <div className="flex items-center gap-3 mb-6 border-b border-white/10 pb-4">
                <Terminal className="w-6 h-6 text-primary" />
                <h2 className="text-xl text-white font-bold">System Installer</h2>
                <button onClick={onClose} className="ml-auto text-white/50 hover:text-white">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-4">
                <div className="flex items-center gap-4 text-sm">
                  <div className="w-2 h-2 rounded-full bg-green-500" />
                  <span className="text-white/70">curl -sL https://nexus-os.tv/install.sh | sudo bash</span>
                </div>

                <div className="bg-black/50 rounded-lg p-4 h-48 overflow-y-auto text-xs font-mono space-y-2 text-green-400/80">
                  <p>&gt; Initializing installer...</p>
                  {step >= 1 && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                      <p>&gt; Detected Ubuntu 24.03 LTS</p>
                      <p>&gt; Verifying hardware compatibility... OK</p>
                      <p>&gt; Downloading core packages...</p>
                    </motion.div>
                  )}
                  {step >= 2 && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                      <p>&gt; Installing Plex Media Server... Done</p>
                      <p>&gt; Installing Kodi... Done</p>
                      <p>&gt; Configuring graphical interface...</p>
                    </motion.div>
                  )}
                  {step >= 3 && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                      <p className="text-white font-bold mt-4">&gt; INSTALLATION COMPLETE</p>
                      <p className="text-white">&gt; Please reboot your system to start Nexus OS.</p>
                    </motion.div>
                  )}
                </div>

                {step === 3 && (
                  <motion.button
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    className="w-full py-3 bg-primary text-white rounded-lg font-bold mt-4 flex items-center justify-center gap-2"
                    onClick={onClose}
                  >
                    <HardDrive className="w-4 h-4" />
                    Reboot System
                  </motion.button>
                )}
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
