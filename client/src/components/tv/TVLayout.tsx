import React from 'react';
import { motion } from 'framer-motion';
import wallpaper from '@assets/generated_images/dark_cinematic_abstract_gradient_background_for_tv_interface.png';

interface TVLayoutProps {
  children: React.ReactNode;
}

export function TVLayout({ children }: TVLayoutProps) {
  return (
    <div className="relative w-screen h-screen overflow-hidden bg-background text-foreground font-body">
      {/* Background Wallpaper with Overlay */}
      <div className="absolute inset-0 z-0">
        <img 
          src={wallpaper} 
          alt="Wallpaper" 
          className="w-full h-full object-cover opacity-80"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/50 to-transparent" />
        <div className="absolute inset-0 bg-black/20 backdrop-blur-[2px]" />
      </div>

      {/* Main Content Layer */}
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1 }}
        className="relative z-10 w-full h-full flex"
      >
        {children}
      </motion.div>
    </div>
  );
}
