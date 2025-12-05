import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface AppCardProps {
  id?: string;
  title: string;
  color: string;
  icon?: React.ReactNode;
  wide?: boolean;
  url?: string;
  onClick?: () => void;
}

export function AppCard({ id, title, color, icon, wide, url, onClick }: AppCardProps) {
  const [isFocused, setIsFocused] = useState(false);

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else if (url) {
      window.open(url, '_blank');
    }
  };

  return (
    <motion.button
      onClick={handleClick}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
      onMouseEnter={() => setIsFocused(true)}
      onMouseLeave={() => setIsFocused(false)}
      whileHover={{ scale: 1.05 }}
      whileFocus={{ scale: 1.05 }}
      data-testid={`app-card-${id || title.toLowerCase().replace(/\s+/g, '-')}`}
      className={cn(
        "relative group rounded-2xl overflow-hidden outline-none border border-white/5 shadow-lg transition-all duration-300 cursor-pointer",
        wide ? "col-span-2 aspect-[2/1]" : "aspect-square",
        isFocused ? "ring-4 ring-white/20 border-white/40 z-10 shadow-2xl" : "z-0"
      )}
    >
      {/* Background Gradient */}
      <div 
        className="absolute inset-0 transition-opacity duration-500"
        style={{ background: color }}
      />
      
      {/* Gloss Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent opacity-50" />
      
      {/* Darkening at bottom for text readability */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent" />

      {/* Focus Glow */}
      {isFocused && (
        <motion.div 
          layoutId={`glow-${id}`}
          className="absolute inset-0 bg-white/10 mix-blend-overlay"
        />
      )}

      {/* Content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
        {icon && (
          <div className="mb-4 transform transition-transform duration-300 group-hover:scale-110 group-focus:scale-110">
            {icon}
          </div>
        )}
        <h3 className="absolute bottom-4 left-4 font-display font-semibold text-xl text-white drop-shadow-md">
          {title}
        </h3>
      </div>
    </motion.button>
  );
}
