import React, { useState } from 'react';
import { TVLayout } from '@/components/tv/TVLayout';
import { Sidebar } from '@/components/tv/Sidebar';
import { AppCard } from '@/components/tv/AppCard';
import { ClockWidget, WeatherWidget } from '@/components/tv/Widgets';
import { InstallModal } from '@/components/tv/InstallModal';
import { Download } from 'lucide-react';
import { motion } from 'framer-motion';

import plexLogo from '@assets/generated_images/plex_app_logo_icon.png';
import netflixLogo from '@assets/generated_images/netflix_app_logo_icon.png';
import primeLogo from '@assets/generated_images/prime_video_app_logo.png';
import spotifyLogo from '@assets/generated_images/spotify_app_logo_icon.png';
import youtubeLogo from '@assets/generated_images/youtube_app_logo_icon.png';
import kodiLogo from '@assets/generated_images/kodi_media_center_logo.png';
import kayoLogo from '@assets/generated_images/kayo_sports_app_logo.png';
import freetubeLogo from '@assets/generated_images/freetube_app_logo_icon.png';
import vacuumtubeLogo from '@assets/generated_images/vacuumtube_app_logo_icon.png';
import chaupalLogo from '@assets/generated_images/chaupal_streaming_app_logo.png';

const apps = [
  { 
    id: 'plex', 
    title: 'Plex', 
    color: 'linear-gradient(135deg, #e5a00d 0%, #1a1a1a 100%)', 
    icon: <img src={plexLogo} alt="Plex" className="w-20 h-20 object-contain rounded-xl" />, 
    wide: true,
    url: 'http://localhost:32400/web'
  },
  { 
    id: 'netflix', 
    title: 'Netflix', 
    color: 'linear-gradient(135deg, #E50914 0%, #141414 100%)', 
    icon: <img src={netflixLogo} alt="Netflix" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://www.netflix.com/browse'
  },
  { 
    id: 'prime', 
    title: 'Prime Video', 
    color: 'linear-gradient(135deg, #00A8E1 0%, #232f3e 100%)', 
    icon: <img src={primeLogo} alt="Prime Video" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://www.primevideo.com'
  },
  { 
    id: 'spotify', 
    title: 'Spotify', 
    color: 'linear-gradient(135deg, #1DB954 0%, #191414 100%)', 
    icon: <img src={spotifyLogo} alt="Spotify" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://open.spotify.com'
  },
  { 
    id: 'youtube', 
    title: 'YouTube', 
    color: 'linear-gradient(135deg, #FF0000 0%, #282828 100%)', 
    icon: <img src={youtubeLogo} alt="YouTube" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://www.youtube.com/tv'
  },
  { 
    id: 'kodi', 
    title: 'Kodi', 
    color: 'linear-gradient(135deg, #17B2E7 0%, #0F2027 100%)', 
    icon: <img src={kodiLogo} alt="Kodi" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'kodi://'
  },
  { 
    id: 'kayo', 
    title: 'Kayo Sports', 
    color: 'linear-gradient(135deg, #00C365 0%, #0a1f12 100%)', 
    icon: <img src={kayoLogo} alt="Kayo Sports" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://kayosports.com.au'
  },
  { 
    id: 'freetube', 
    title: 'FreeTube', 
    color: 'linear-gradient(135deg, #364F6B 0%, #1E2A38 100%)', 
    icon: <img src={freetubeLogo} alt="FreeTube" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'freetube://'
  },
  { 
    id: 'vacuumtube', 
    title: 'VacuumTube', 
    color: 'linear-gradient(135deg, #6B364F 0%, #1a0f14 100%)', 
    icon: <img src={vacuumtubeLogo} alt="VacuumTube" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://www.youtube.com/tv'
  },
  { 
    id: 'chaupal', 
    title: 'Chaupal', 
    color: 'linear-gradient(135deg, #FF512F 0%, #DD2476 100%)', 
    icon: <img src={chaupalLogo} alt="Chaupal" className="w-16 h-16 object-contain rounded-xl" />,
    url: 'https://chaupal.tv'
  },
];

export default function Home() {
  const [isInstallModalOpen, setIsInstallModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('home');

  return (
    <TVLayout>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
      
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
            <h2 className="text-white/60 font-medium mb-6 tracking-wide uppercase text-sm" data-testid="section-continue-watching">Continue Watching</h2>
            <div className="grid grid-cols-3 gap-6">
               <motion.div 
                 whileHover={{ scale: 1.02 }}
                 className="col-span-2 h-64 rounded-2xl bg-black/40 border border-white/10 relative overflow-hidden group cursor-pointer"
                 data-testid="featured-interstellar"
               >
                 <img src="https://images.unsplash.com/photo-1626814026160-2237a95fc5a0?q=80&w=2940&auto=format&fit=crop" alt="Movie" className="w-full h-full object-cover opacity-60 group-hover:opacity-80 transition-opacity" />
                 <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
                 <div className="absolute bottom-6 left-6">
                    <div className="text-xs font-bold text-primary mb-2 uppercase tracking-wider">Ready to resume</div>
                    <h3 className="text-3xl font-display font-bold text-white">Interstellar</h3>
                    <div className="w-48 h-1 bg-white/20 rounded-full mt-4 overflow-hidden">
                      <div className="w-[75%] h-full bg-primary" />
                    </div>
                 </div>
               </motion.div>

               <motion.div 
                 whileHover={{ scale: 1.02 }}
                 className="h-64 rounded-2xl bg-black/40 border border-white/10 relative overflow-hidden group cursor-pointer"
                 data-testid="featured-bladerunner"
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
            <h2 className="text-white/60 font-medium mb-6 tracking-wide uppercase text-sm" data-testid="section-your-apps">Your Apps</h2>
            <div className="grid grid-cols-5 gap-6">
              {apps.map((app) => (
                <AppCard 
                  key={app.id}
                  id={app.id}
                  title={app.title}
                  color={app.color}
                  icon={app.icon}
                  wide={app.wide}
                  url={app.url}
                />
              ))}
              
              {/* Install Button */}
              <AppCard 
                id="install"
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
