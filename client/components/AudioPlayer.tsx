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
      <div className="gradient-card p-6 rounded-xl border border-border">
        <div className="flex items-center space-x-4">
          <div className="w-12 h-12 rounded-lg bg-primary/20 animate-pulse-slow flex items-center justify-center">
            <Volume2 className="h-6 w-6 text-primary" />
          </div>
          <div className="flex-1">
            <div className="h-4 bg-muted rounded animate-pulse mb-2"></div>
            <div className="h-3 bg-muted/50 rounded w-2/3 animate-pulse"></div>
          </div>
        </div>
        <div className="mt-4 flex space-x-1">
          {Array.from({ length: 50 }).map((_, i) => (
            <div
              key={i}
              className="flex-1 bg-muted animate-pulse rounded-sm"
              style={{ height: `${Math.random() * 40 + 10}px` }}
            />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="gradient-card p-6 rounded-xl border border-border hover:border-primary/50 transition-colors">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-4">
          <Button
            onClick={onPlayPause}
            size="lg"
            className="w-12 h-12 rounded-xl gradient-primary border-0 hover:scale-105 transition-transform"
          >
            {isPlaying ? (
              <Pause className="h-5 w-5" />
            ) : (
              <Play className="h-5 w-5 ml-0.5" />
            )}
          </Button>
          <div>
            <h3 className="font-semibold text-foreground">{layerName}</h3>
            <p className="text-sm text-muted-foreground">
              {Math.floor(currentTime)}s / {duration}s
            </p>
          </div>
        </div>
        <Volume2 className="h-5 w-5 text-muted-foreground" />
      </div>

      {/* Waveform Visualization */}
      <div className="flex items-end space-x-1 h-16">
        {waveformBars.map((bar, i) => (
          <div
            key={i}
            className={`flex-1 rounded-sm transition-all duration-150 ${
              bar.isActive
                ? "bg-gradient-to-t from-primary to-accent"
                : "bg-muted"
            }`}
            style={{
              height: `${bar.height * 100}%`,
              opacity: bar.isActive ? 1 : 0.6,
            }}
          />
        ))}
      </div>

      {/* Progress Bar */}
      <div className="mt-4 w-full bg-muted rounded-full h-1">
        <div
          className="bg-gradient-to-r from-primary to-accent h-1 rounded-full transition-all duration-100"
          style={{ width: `${(currentTime / duration) * 100}%` }}
        />
      </div>
    </div>
  );
}
