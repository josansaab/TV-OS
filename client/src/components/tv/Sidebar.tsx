import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Home, Search, Settings, User, Grid, Power } from 'lucide-react';
import { cn } from '@/lib/utils';

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
              {isHovered && (
                <motion.div
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  className="absolute left-full ml-4 px-3 py-1.5 bg-white/10 backdrop-blur-md rounded-lg text-sm text-white whitespace-nowrap z-50"
                >
                  {item.label}
                </motion.div>
              )}
            </motion.button>
          );
        })}
      </nav>

      <div className="mt-auto">
        <motion.button 
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          className="p-3 rounded-xl text-white/40 hover:text-red-400 transition-colors hover:bg-white/5"
          data-testid="button-power"
        >
          <Power className="w-6 h-6" />
        </motion.button>
      </div>
    </div>
  );
}
