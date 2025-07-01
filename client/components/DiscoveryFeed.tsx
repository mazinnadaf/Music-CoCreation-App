import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Heart,
  Play,
  Share,
  Users,
  Zap,
  TrendingUp,
  Plus,
  Music,
} from "lucide-react";

interface Track {
  id: string;
  title: string;
  artist: string;
  avatar: string;
  genre: string;
  duration: string;
  likes: number;
  collaborators: number;
  isOpen: boolean;
  type: "track" | "stem" | "collaboration";
  description?: string;
}

const MOCK_TRACKS: Track[] = [
  {
    id: "1",
    title: "Midnight Dreams",
    artist: "Alex Chen",
    avatar: "AC",
    genre: "Lo-Fi",
    duration: "2:34",
    likes: 234,
    collaborators: 3,
    isOpen: false,
    type: "track",
  },
  {
    id: "2",
    title: "Punchy Drum Loop",
    artist: "beatmaker_sam",
    avatar: "BS",
    genre: "Hip-Hop",
    duration: "0:16",
    likes: 89,
    collaborators: 0,
    isOpen: true,
    type: "stem",
    description: "Need someone to add melody and bass to this groove",
  },
  {
    id: "3",
    title: "Finish My Synthwave Track",
    artist: "RetroWave Studios",
    avatar: "RW",
    genre: "Synthwave",
    duration: "1:45",
    likes: 156,
    collaborators: 2,
    isOpen: true,
    type: "collaboration",
    description: "Looking for a vocalist to complete this 80s-inspired track",
  },
  {
    id: "4",
    title: "Ocean Waves",
    artist: "Luna Martinez",
    avatar: "LM",
    genre: "Ambient",
    duration: "3:12",
    likes: 445,
    collaborators: 1,
    isOpen: false,
    type: "track",
  },
  {
    id: "5",
    title: "Smooth Jazz Bass",
    artist: "JazzCat",
    avatar: "JC",
    genre: "Jazz",
    duration: "0:32",
    likes: 67,
    collaborators: 0,
    isOpen: true,
    type: "stem",
    description: "Perfect foundation for a chill jazz track",
  },
];

export default function DiscoveryFeed() {
  const [likedTracks, setLikedTracks] = useState<Set<string>>(new Set());
  const [filter, setFilter] = useState<"all" | "tracks" | "stems" | "collabs">(
    "all",
  );

  const toggleLike = (trackId: string) => {
    setLikedTracks((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(trackId)) {
        newSet.delete(trackId);
      } else {
        newSet.add(trackId);
      }
      return newSet;
    });
  };

  const filteredTracks = MOCK_TRACKS.filter((track) => {
    if (filter === "tracks") return track.type === "track";
    if (filter === "stems") return track.type === "stem";
    if (filter === "collabs") return track.type === "collaboration";
    return true;
  });

  const getTypeIcon = (type: Track["type"]) => {
    switch (type) {
      case "track":
        return <Music className="h-4 w-4" />;
      case "stem":
        return <Zap className="h-4 w-4" />;
      case "collaboration":
        return <Users className="h-4 w-4" />;
    }
  };

  const getTypeColor = (type: Track["type"]) => {
    switch (type) {
      case "track":
        return "bg-blue-500/20 text-blue-400 border-blue-500/30";
      case "stem":
        return "bg-purple-500/20 text-purple-400 border-purple-500/30";
      case "collaboration":
        return "bg-accent/20 text-accent border-accent/30";
    }
  };

  return (
    <div className="w-full px-3 py-3 space-y-3 min-h-full">
      {/* Header - Mobile optimized */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">Discover</h1>
          <div className="flex items-center space-x-1.5">
            <TrendingUp className="h-4 w-4 text-accent" />
            <span className="text-xs text-accent font-medium">Trending</span>
          </div>
        </div>
        <p className="text-muted-foreground text-xs leading-relaxed">
          Find your next collaboration or inspiration
        </p>
      </div>

      {/* Filters - Mobile horizontal scroll */}
      <div className="w-full overflow-x-auto scrollbar-hide">
        <div className="flex space-x-2 pb-2 min-w-max px-1">
          {[
            { key: "all", label: "All" },
            { key: "tracks", label: "Tracks" },
            { key: "stems", label: "Stems" },
            { key: "collabs", label: "Collabs" },
          ].map((filterOption) => (
            <Button
              key={filterOption.key}
              variant={filter === filterOption.key ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter(filterOption.key as typeof filter)}
              className={`whitespace-nowrap active:scale-95 transition-transform ${
                filter === filterOption.key
                  ? "gradient-primary border-0 shadow-md"
                  : "border-border hover:border-primary/50"
              }`}
            >
              {filterOption.label}
            </Button>
          ))}
        </div>
      </div>

      {/* Feed - Mobile optimized spacing */}
      <div className="space-y-4">
        {filteredTracks.map((track) => (
          <Card
            key={track.id}
            className="gradient-card p-3 border-border active:border-primary/50 transition-colors"
          >
            <div className="flex items-start space-x-4">
              {/* Avatar */}
              <Avatar className="w-12 h-12">
                <AvatarImage src="" />
                <AvatarFallback className="gradient-primary text-white font-semibold">
                  {track.avatar}
                </AvatarFallback>
              </Avatar>

              {/* Content */}
              <div className="flex-1 space-y-3">
                <div className="flex items-start justify-between">
                  <div>
                    <div className="flex items-center space-x-2">
                      <h3 className="font-semibold text-lg">{track.title}</h3>
                      <Badge
                        variant="outline"
                        className={`${getTypeColor(track.type)} text-xs`}
                      >
                        {getTypeIcon(track.type)}
                        <span className="ml-1 capitalize">{track.type}</span>
                      </Badge>
                      {track.isOpen && (
                        <Badge
                          variant="outline"
                          className="bg-green-500/20 text-green-400 border-green-500/30 text-xs"
                        >
                          Open
                        </Badge>
                      )}
                    </div>
                    <p className="text-muted-foreground">
                      by {track.artist} • {track.genre} • {track.duration}
                    </p>
                    {track.description && (
                      <p className="text-sm text-foreground/80 mt-2">
                        {track.description}
                      </p>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <Button size="sm" className="gradient-primary border-0">
                      <Play className="h-4 w-4 mr-2" />
                      Play
                    </Button>
                    {track.isOpen && (
                      <Button size="sm" variant="outline">
                        <Plus className="h-4 w-4 mr-2" />
                        {track.type === "collaboration" ? "Join" : "Use Stem"}
                      </Button>
                    )}
                  </div>

                  <div className="flex items-center space-x-3 text-sm text-muted-foreground">
                    <button
                      onClick={() => toggleLike(track.id)}
                      className={`flex items-center space-x-1 hover:text-red-400 transition-colors ${
                        likedTracks.has(track.id) ? "text-red-400" : ""
                      }`}
                    >
                      <Heart
                        className={`h-4 w-4 ${
                          likedTracks.has(track.id) ? "fill-current" : ""
                        }`}
                      />
                      <span>{track.likes}</span>
                    </button>

                    {track.collaborators > 0 && (
                      <div className="flex items-center space-x-1">
                        <Users className="h-4 w-4" />
                        <span>{track.collaborators}</span>
                      </div>
                    )}

                    <button className="flex items-center space-x-1 hover:text-foreground transition-colors">
                      <Share className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Load More - Mobile optimized */}
      <div className="pt-4">
        <Button
          variant="outline"
          className="w-full border-border hover:border-primary/50 active:scale-[0.98] transition-transform p-2.5 h-auto text-xs"
        >
          Load More Tracks
        </Button>
      </div>
    </div>
  );
}
