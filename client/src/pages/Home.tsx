import React, { useState } from 'react';
import { TVLayout } from '@/components/tv/TVLayout';
import { Sidebar } from '@/components/tv/Sidebar';
import { AppCard } from '@/components/tv/AppCard';
import { ClockWidget, WeatherWidget } from '@/components/tv/Widgets';
import { InstallModal } from '@/components/tv/InstallModal';
import { Download } from 'lucide-react';
import { motion } from 'framer-motion';

import plexLogo from '@assets/stock_images/plex_media_server_lo_e18675d2.jpg';
import netflixLogo from '@assets/stock_images/netflix_logo_icon_re_3b0e1652.jpg';
import primeLogo from '@assets/stock_images/amazon_prime_video_l_a2a4296d.jpg';
import spotifyLogo from '@assets/stock_images/spotify_music_logo_g_cbe94d1b.jpg';
import youtubeLogo from '@assets/stock_images/youtube_logo_red_pla_0d8f38b0.jpg';
import kodiLogo from '@assets/stock_images/kodi_media_center_lo_d53854ff.jpg';

const apps = [
  { 
    id: 'plex', 
    title: 'Plex', 
    color: 'linear-gradient(135deg, #e5a00d 0%, #b57d08 100%)', 
    icon: <img src={plexLogo} alt="Plex" className="w-16 h-16 object-contain" />, 
    wide: true 
  },
  { 
    id: 'netflix', 
    title: 'Netflix', 
    color: 'linear-gradient(135deg, #E50914 0%, #B20710 100%)', 
    icon: <img src={netflixLogo} alt="Netflix" className="w-16 h-16 object-contain" />
  },
  { 
    id: 'prime', 
    title: 'Prime Video', 
    color: 'linear-gradient(135deg, #00A8E1 0%, #0078A0 100%)', 
    icon: <img src={primeLogo} alt="Prime Video" className="w-16 h-16 object-contain" />
  },
  { 
    id: 'spotify', 
    title: 'Spotify', 
    color: 'linear-gradient(135deg, #1DB954 0%, #191414 100%)', 
    icon: <img src={spotifyLogo} alt="Spotify" className="w-16 h-16 object-contain" />
  },
  { 
    id: 'youtube', 
    title: 'YouTube', 
    color: 'linear-gradient(135deg, #FF0000 0%, #CC0000 100%)', 
    icon: <img src={youtubeLogo} alt="YouTube" className="w-20 h-20 object-contain" />
  },
  { 
    id: 'kodi', 
    title: 'Kodi', 
    color: 'linear-gradient(135deg, #17B2E7 0%, #0F8AB5 100%)', 
    icon: <img src={kodiLogo} alt="Kodi" className="w-16 h-16 object-contain" />
  },
  { 
    id: 'kayo', 
    title: 'Kayo Sports', 
    color: 'linear-gradient(135deg, #00C365 0%, #008F4A 100%)', 
    icon: <span className="text-4xl font-bold italic text-white">KAYO</span>
  },
  { 
    id: 'freetube', 
    title: 'FreeTube', 
    color: 'linear-gradient(135deg, #364F6B 0%, #1E2A38 100%)', 
    icon: <span className="text-3xl font-bold text-white">FT</span>
  },
  { 
    id: 'vaccum', 
    title: 'VacuumTube', 
    color: 'linear-gradient(135deg, #6B364F 0%, #381E2A 100%)', 
    icon: <span className="text-3xl font-bold text-pink-300">VT</span>
  },
  { 
    id: 'chaupal', 
    title: 'Chaupal', 
    color: 'linear-gradient(135deg, #FF512F 0%, #DD2476 100%)', 
    icon: <span className="text-4xl font-bold text-white">चौपाल</span>
  },
];

export default function Home() {
  const [isInstallModalOpen, setIsInstallModalOpen] = useState(false);

  return (
    <TVLayout>
      <Sidebar />
      
      <InstallModal isOpen={isInstallModalOpen} onClose={() => setIsInstallModalOpen(false)} />

      <main className="flex-1 p-12 pl-4 flex flex-col h-screen">
        {/* Header Section */}
        <header className="flex justify-between items-start mb-12">
          <WeatherWidget />
          <ClockWidget />
        </header>

        {/* Scrollable Content Area */}
        <div className="flex-1 overflow-y-auto no-scrollbar pr-8 pb-12">
          
          {/* Featured Section */}
          <section className="mb-10">
            <h2 className="text-xl text-white/60 font-medium mb-6 tracking-wide uppercase text-sm">Continue Watching</h2>
            <div className="grid grid-cols-3 gap-6">
               <motion.div 
                 whileHover={{ scale: 1.02 }}
                 className="col-span-2 h-64 rounded-2xl bg-black/40 border border-white/10 relative overflow-hidden group cursor-pointer"
               >
                 <img src="https://images.unsplash.com/photo-1626814026160-2237a95fc5a0?q=80&w=2940&auto=format&fit=crop" alt="Movie" className="w-full h-full object-cover opacity-60 group-hover:opacity-80 transition-opacity" />
                 <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
                 <div className="absolute bottom-6 left-6">
                    <div className="text-xs font-bold text-primary mb-2 uppercase tracking-wider">Ready to resume</div>
                    <h3 className="text-3xl font-display font-bold text-white">Interstellar</h3>
                    <div className="w-full h-1 bg-white/20 rounded-full mt-4 overflow-hidden">
                      <div className="w-[75%] h-full bg-primary" />
                    </div>
                 </div>
               </motion.div>

               <motion.div 
                 whileHover={{ scale: 1.02 }}
                 className="h-64 rounded-2xl bg-black/40 border border-white/10 relative overflow-hidden group cursor-pointer"
               >
                  <img src="https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=2825&auto=format&fit=crop" alt="Show" className="w-full h-full object-cover opacity-60 group-hover:opacity-80 transition-opacity" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
                  <div className="absolute bottom-6 left-6">
                    <h3 className="text-2xl font-display font-bold text-white">Blade Runner</h3>
                  </div>
               </motion.div>
            </div>
          </section>

          {/* Apps Grid */}
          <section>
            <h2 className="text-xl text-white/60 font-medium mb-6 tracking-wide uppercase text-sm">Your Apps</h2>
            <div className="grid grid-cols-5 gap-6">
              {apps.map((app) => (
                <AppCard 
                  key={app.id}
                  title={app.title}
                  color={app.color}
                  icon={app.icon}
                  wide={app.wide}
                />
              ))}
              
              {/* Install Button */}
              <AppCard 
                title="Install on Ubuntu"
                color="linear-gradient(135deg, #22c55e 0%, #166534 100%)"
                icon={<Download className="w-10 h-10 text-white" />}
                onClick={() => setIsInstallModalOpen(true)}
              />
            </div>
          </section>
        </div>
      </main>
    </TVLayout>
  );
}
