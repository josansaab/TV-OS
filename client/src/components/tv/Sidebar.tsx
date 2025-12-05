import React from 'react';
import { motion } from 'framer-motion';
import { Home, Search, Settings, User, Grid, Power } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { icon: Search, label: 'Search' },
  { icon: Home, label: 'Home', active: true },
  { icon: Grid, label: 'Apps' },
  { icon: User, label: 'Profile' },
  { icon: Settings, label: 'Settings' },
];

export function Sidebar() {
  return (
    <div className="h-full w-24 flex flex-col items-center py-10 z-50 relative">
      <div className="mb-12">
        <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center border border-white/10">
          <div className="w-6 h-6 bg-primary rounded-full shadow-[0_0_15px_rgba(124,58,237,0.5)]" />
        </div>
      </div>

      <nav className="flex-1 flex flex-col gap-8">
        {navItems.map((item, i) => (
          <button
            key={item.label}
            className={cn(
              "p-3 rounded-xl transition-all duration-300 group relative outline-none",
              item.active 
                ? "text-white" 
                : "text-white/40 hover:text-white/80"
            )}
          >
            {item.active && (
              <motion.div
                layoutId="activeNav"
                className="absolute inset-0 bg-white/10 rounded-xl"
                transition={{ type: "spring", stiffness: 300, damping: 30 }}
              />
            )}
            <item.icon className={cn("w-6 h-6 relative z-10", item.active && "drop-shadow-[0_0_8px_rgba(255,255,255,0.5)]")} />
            <span className="sr-only">{item.label}</span>
          </button>
        ))}
      </nav>

      <div className="mt-auto">
         <button className="p-3 rounded-xl text-white/40 hover:text-red-400 transition-colors hover:bg-white/5">
          <Power className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
}
