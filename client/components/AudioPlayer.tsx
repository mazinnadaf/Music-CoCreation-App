import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Play, Pause, Volume2 } from "lucide-react";

interface AudioPlayerProps {
  layerName: string;
  isPlaying?: boolean;
  onPlayPause?: () => void;
  isLoading?: boolean;
}

export default function AudioPlayer({
  layerName,
  isPlaying = false,
  onPlayPause,
  isLoading = false,
}: AudioPlayerProps) {
  const [currentTime, setCurrentTime] = useState(0);
  const duration = 30; // 30 second loop

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isPlaying) {
      interval = setInterval(() => {
        setCurrentTime((prev) => (prev + 0.1) % duration);
      }, 100);
    }
    return () => clearInterval(interval);
  }, [isPlaying, duration]);

  // Generate fake waveform data
  const waveformBars = Array.from({ length: 50 }, (_, i) => ({
    height: Math.sin(i * 0.2) * 0.5 + 0.5 + Math.random() * 0.3,
    isActive: (currentTime / duration) * 50 > i,
  }));

  if (isLoading) {
    return (
      <div className="gradient-card p-4 rounded-xl border border-border">
        <div className="flex items-center space-x-3">
          <div className="w-12 h-12 rounded-xl bg-primary/20 animate-pulse-slow flex items-center justify-center">
            <Volume2 className="h-5 w-5 text-primary" />
          </div>
          <div className="flex-1 space-y-2">
            <div className="h-3 bg-muted rounded animate-pulse"></div>
            <div className="h-2 bg-muted/50 rounded w-2/3 animate-pulse"></div>
          </div>
        </div>
        <div className="mt-3 flex space-x-0.5 h-12">
          {Array.from({ length: 40 }).map((_, i) => (
            <div
              key={i}
              className="flex-1 bg-muted animate-pulse rounded-sm"
              style={{
                height: `${Math.random() * 100 + 20}%`,
                animationDelay: `${i * 0.02}s`,
              }}
            />
          ))}
        </div>
        <div className="mt-3 h-2 bg-muted rounded-full animate-pulse"></div>
      </div>
    );
  }

  return (
    <div className="gradient-card p-3 rounded-lg border border-border active:border-primary/50 transition-colors">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <Button
            onClick={onPlayPause}
            className="w-10 h-10 rounded-lg gradient-primary border-0 active:scale-95 transition-all duration-200 shadow-md"
          >
            {isPlaying ? (
              <Pause className="h-4 w-4" />
            ) : (
              <Play className="h-4 w-4 ml-0.5" />
            )}
          </Button>
          <div className="min-w-0 flex-1">
            <h3 className="font-medium text-foreground text-xs leading-tight truncate">
              {layerName}
            </h3>
            <p className="text-xs text-muted-foreground">
              {Math.floor(currentTime)}s / {duration}s
            </p>
          </div>
        </div>
        <Button variant="ghost" size="sm" className="w-8 h-8 p-0 rounded-lg">
          <Volume2 className="h-4 w-4 text-muted-foreground" />
        </Button>
      </div>

      {/* Waveform Visualization - Mobile optimized */}
      <div className="flex items-end space-x-0.5 h-12 mb-3">
        {waveformBars.map((bar, i) => (
          <div
            key={i}
            className={`flex-1 rounded-sm transition-all duration-150 ${
              bar.isActive
                ? "bg-gradient-to-t from-primary to-accent"
                : "bg-muted"
            }`}
            style={{
              height: `${Math.max(bar.height * 100, 8)}%`,
              opacity: bar.isActive ? 1 : 0.6,
            }}
          />
        ))}
      </div>

      {/* Progress Bar - Larger touch target */}
      <div
        className="w-full bg-muted rounded-full h-2 cursor-pointer"
        onClick={(e) => {
          // Add click-to-seek functionality
          const rect = e.currentTarget.getBoundingClientRect();
          const clickX = e.clientX - rect.left;
          const percentage = clickX / rect.width;
          // Would update currentTime here
        }}
      >
        <div
          className="bg-gradient-to-r from-primary to-accent h-2 rounded-full transition-all duration-100"
          style={{ width: `${(currentTime / duration) * 100}%` }}
        />
      </div>
    </div>
  );
}
