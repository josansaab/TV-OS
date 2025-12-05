import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Home, Search, Settings, User, Grid, Power, LogOut } from 'lucide-react';
import { cn } from '@/lib/utils';
import { systemPower } from '@/lib/api';

const navItems = [
  { icon: Search, label: 'Search', id: 'search' },
  { icon: Home, label: 'Home', id: 'home' },
  { icon: Grid, label: 'Apps', id: 'apps' },
  { icon: User, label: 'Profile', id: 'profile' },
  { icon: Settings, label: 'Settings', id: 'settings' },
];

interface SidebarProps {
  activeTab?: string;
  onTabChange?: (tab: string) => void;
}

export function Sidebar({ activeTab = 'home', onTabChange }: SidebarProps) {
  const [hoveredItem, setHoveredItem] = useState<string | null>(null);
  const [showPowerMenu, setShowPowerMenu] = useState(false);

  const handlePower = async (action: 'shutdown' | 'restart') => {
    setShowPowerMenu(false);
    await systemPower(action);
  };

  const handleExitKiosk = () => {
    setShowPowerMenu(false);
    window.close();
  };

  return (
    <div className="h-full w-24 flex flex-col items-center py-10 z-50 relative">
      <div className="mb-12">
        <motion.div 
          whileHover={{ scale: 1.1 }}
          className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center border border-white/10 cursor-pointer"
          data-testid="logo"
        >
          <div className="w-6 h-6 bg-primary rounded-full shadow-[0_0_15px_rgba(124,58,237,0.5)]" />
        </motion.div>
      </div>

      <nav className="flex-1 flex flex-col gap-6">
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          const isHovered = hoveredItem === item.id;
          
          return (
            <motion.button
              key={item.id}
              onClick={() => onTabChange?.(item.id)}
              onMouseEnter={() => setHoveredItem(item.id)}
              onMouseLeave={() => setHoveredItem(null)}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
              data-testid={`nav-${item.id}`}
              className={cn(
                "p-3 rounded-xl transition-all duration-300 group relative outline-none",
                isActive 
                  ? "text-white" 
                  : "text-white/40 hover:text-white/80"
              )}
            >
              {isActive && (
                <motion.div
                  layoutId="activeNav"
                  className="absolute inset-0 bg-white/10 rounded-xl"
                  transition={{ type: "spring", stiffness: 300, damping: 30 }}
                />
              )}
              <item.icon 
                className={cn(
                  "w-6 h-6 relative z-10 transition-all", 
                  isActive && "drop-shadow-[0_0_8px_rgba(255,255,255,0.5)]"
                )} 
              />
              
              {/* Tooltip */}
              <AnimatePresence>
                {isHovered && (
                  <motion.div
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -10 }}
                    className="absolute left-full ml-4 px-3 py-1.5 bg-white/10 backdrop-blur-md rounded-lg text-sm text-white whitespace-nowrap z-50"
                  >
                    {item.label}
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.button>
          );
        })}
      </nav>

      <div className="mt-auto relative">
        <motion.button 
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => setShowPowerMenu(!showPowerMenu)}
          className="p-3 rounded-xl text-white/40 hover:text-red-400 transition-colors hover:bg-white/5"
          data-testid="button-power"
        >
          <Power className="w-6 h-6" />
        </motion.button>

        {/* Power Menu */}
        <AnimatePresence>
          {showPowerMenu && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9, x: -10 }}
              animate={{ opacity: 1, scale: 1, x: 0 }}
              exit={{ opacity: 0, scale: 0.9, x: -10 }}
              className="absolute left-full bottom-0 ml-4 bg-black/80 backdrop-blur-xl rounded-xl border border-white/10 overflow-hidden z-50"
            >
              <button
                onClick={handleExitKiosk}
                className="w-full px-6 py-3 text-left text-white hover:bg-white/10 transition-colors flex items-center gap-3"
                data-testid="button-exit-kiosk"
              >
                <LogOut className="w-4 h-4 text-blue-400" /> Exit Kiosk
              </button>
              <button
                onClick={() => handlePower('restart')}
                className="w-full px-6 py-3 text-left text-white hover:bg-white/10 transition-colors flex items-center gap-3 border-t border-white/10"
                data-testid="button-restart"
              >
                <span className="text-yellow-400">↻</span> Restart
              </button>
              <button
                onClick={() => handlePower('shutdown')}
                className="w-full px-6 py-3 text-left text-white hover:bg-white/10 transition-colors flex items-center gap-3 border-t border-white/10"
                data-testid="button-shutdown"
              >
                <span className="text-red-400">⏻</span> Shut Down
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
