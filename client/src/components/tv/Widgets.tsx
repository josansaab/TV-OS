import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { motion } from 'framer-motion';
import { Cloud, CloudRain, Sun, Wind } from 'lucide-react';

export function WeatherWidget() {
  // Mock weather data
  const weather = {
    temp: 72,
    condition: 'Partly Cloudy',
    high: 78,
    low: 65
  };

  return (
    <motion.div 
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      className="flex items-center gap-4 text-white/90 p-4 rounded-2xl bg-white/5 backdrop-blur-md border border-white/10"
    >
      <div className="p-3 bg-blue-500/20 rounded-full text-blue-300">
        <Cloud className="w-8 h-8" />
      </div>
      <div>
        <div className="flex items-baseline gap-2">
          <span className="text-3xl font-display font-bold">{weather.temp}°</span>
          <span className="text-sm font-medium opacity-60">{weather.condition}</span>
        </div>
        <div className="text-xs opacity-50 font-medium">
          H:{weather.high}° L:{weather.low}°
        </div>
      </div>
    </motion.div>
  );
}

export function ClockWidget() {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="text-right">
      <motion.h1 
        key={format(time, 'HH:mm')}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-6xl font-display font-light text-white tracking-tight drop-shadow-lg"
      >
        {format(time, 'h:mm')}
        <span className="text-2xl ml-2 opacity-50 font-normal">{format(time, 'a')}</span>
      </motion.h1>
      <p className="text-lg text-white/60 font-medium mt-1 uppercase tracking-widest text-sm">
        {format(time, 'EEEE, MMMM do')}
      </p>
    </div>
  );
}
