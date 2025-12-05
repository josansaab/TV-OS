import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';
import { launchApp } from '@/lib/api';
import { useToast } from '@/hooks/use-toast';

interface AppCardProps {
  id?: string;
  title: string;
  color: string;
  icon?: React.ReactNode;
  wide?: boolean;
  onClick?: () => void;
}

export function AppCard({ id, title, color, icon, wide, onClick }: AppCardProps) {
  const [isFocused, setIsFocused] = useState(false);
  const [isLaunching, setIsLaunching] = useState(false);
  const { toast } = useToast();

  const handleClick = async () => {
    if (onClick) {
      onClick();
      return;
    }
    
    if (id) {
      setIsLaunching(true);
      const result = await launchApp(id);
      setIsLaunching(false);
      
      if (result.success) {
        toast({
          title: `Launching ${title}`,
          description: "The app is starting...",
        });
      } else {
        toast({
          title: "Launch Failed",
          description: result.error || "Could not start the app",
          variant: "destructive",
        });
      }
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
      disabled={isLaunching}
      data-testid={`app-card-${id || title.toLowerCase().replace(/\s+/g, '-')}`}
      className={cn(
        "relative group rounded-2xl overflow-hidden outline-none border border-white/5 shadow-lg transition-all duration-300 cursor-pointer",
        wide ? "col-span-2 aspect-[2/1]" : "aspect-square",
        isFocused ? "ring-4 ring-white/20 border-white/40 z-10 shadow-2xl" : "z-0",
        isLaunching && "opacity-70"
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

      {/* Loading Indicator */}
      {isLaunching && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/50 z-20">
          <div className="w-8 h-8 border-3 border-white/30 border-t-white rounded-full animate-spin" />
        </div>
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
