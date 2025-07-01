import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Card } from "@/components/ui/card";
import { Sparkles, Zap, Music, Mic } from "lucide-react";
import AudioPlayer from "./AudioPlayer";

interface Layer {
  id: string;
  name: string;
  prompt: string;
  isPlaying: boolean;
}

const SUGGESTED_PROMPTS = [
  "a chill dreamy melody that sounds like a sunset",
  "some bouncy drums that make you want to dance",
  "a deep bass that hits just right",
  "soft background vibes for studying",
  "happy acoustic guitar like a coffee shop",
];

export default function CreateLayer() {
  const [prompt, setPrompt] = useState(SUGGESTED_PROMPTS[0]);
  const [layers, setLayers] = useState<Layer[]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [showSuggestion, setShowSuggestion] = useState(true);

  const handleCreateLayer = async () => {
    if (!prompt.trim()) return;

    setIsGenerating(true);
    setShowSuggestion(false);

    // Simulate AI generation delay
    setTimeout(
      () => {
        const newLayer: Layer = {
          id: Date.now().toString(),
          name: prompt.split(",")[0].trim(),
          prompt,
          isPlaying: false,
        };

        setLayers((prev) => [...prev, newLayer]);
        setIsGenerating(false);

        // Auto-play the new layer
        setTimeout(() => {
          toggleLayerPlayback(newLayer.id);
        }, 500);

        // Show next suggestion
        if (layers.length === 0) {
          setPrompt(SUGGESTED_PROMPTS[1]);
          setShowSuggestion(true);
        } else {
          setPrompt("");
        }
      },
      2000 + Math.random() * 3000,
    ); // 2-5 seconds
  };

  const toggleLayerPlayback = (layerId: string) => {
    setLayers((prev) =>
      prev.map((layer) =>
        layer.id === layerId
          ? { ...layer, isPlaying: !layer.isPlaying }
          : layer,
      ),
    );
  };

  const suggestPrompt = (suggestion: string) => {
    setPrompt(suggestion);
    setShowSuggestion(false);
  };

  return (
    <div className="w-full px-3 py-3 space-y-3 min-h-full">
      {/* Header - Consumer friendly */}
      <div className="text-center space-y-2">
        <h1 className="text-lg font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent leading-tight">
          What's your vibe?
        </h1>
        <p className="text-xs text-muted-foreground px-1 leading-relaxed">
          Just describe the sound in your head and watch the magic happen ✨
        </p>
      </div>

      {/* Creation Interface - Mobile optimized */}
      <Card className="gradient-card p-3 border-border">
        <div className="space-y-4">
          <div className="flex items-center space-x-2 text-sm text-muted-foreground">
            <Sparkles className="h-4 w-4" />
            <span>Describe your sound</span>
          </div>

          <Textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Something that sounds like..."
            className="min-h-[80px] text-sm leading-relaxed bg-background/50 border-border focus:border-primary/50 rounded-lg p-3 resize-none"
            style={{
              fontSize: "16px", // Prevent zoom on iOS
              lineHeight: "1.5",
            }}
          />

          {/* Suggested Prompts - Mobile stacked */}
          {showSuggestion && layers.length === 0 && (
            <div className="space-y-3">
              <span className="text-sm text-muted-foreground block">
                💡 Or try one of these vibes:
              </span>
              <div className="grid gap-2">
                {SUGGESTED_PROMPTS.slice(1, 4).map((suggestion, i) => (
                  <Button
                    key={i}
                    variant="outline"
                    size="sm"
                    onClick={() => suggestPrompt(suggestion)}
                    className="text-xs p-2.5 h-auto text-left justify-start border-border hover:border-primary/50 active:scale-[0.98] transition-transform"
                  >
                    <span className="text-lg mr-2">
                      {i === 0 ? "🥁" : i === 1 ? "🎸" : "☁️"}
                    </span>
                    {suggestion}
                  </Button>
                ))}
              </div>
            </div>
          )}

          {showSuggestion && layers.length === 1 && (
            <div className="bg-accent/10 border border-accent/20 rounded-xl p-4 space-y-3">
              <div className="flex items-start space-x-3">
                <div className="w-8 h-8 rounded-full bg-accent/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-lg">🔥</span>
                </div>
                <div className="space-y-2 flex-1">
                  <span className="font-medium text-accent block leading-tight">
                    That's fire! Now let's add some beats 🥁
                  </span>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    Every great song needs some rhythm to get people moving:
                  </p>
                </div>
              </div>
              <Button
                variant="outline"
                onClick={() => suggestPrompt(SUGGESTED_PROMPTS[1])}
                className="w-full p-2.5 h-auto text-left justify-start border-accent/20 hover:border-accent/50 text-accent text-xs active:scale-[0.98] transition-transform"
              >
                {SUGGESTED_PROMPTS[1]}
              </Button>
            </div>
          )}

          <Button
            onClick={handleCreateLayer}
            disabled={!prompt.trim() || isGenerating}
            className="w-full gradient-primary border-0 active:scale-[0.98] transition-all duration-200 text-sm font-semibold py-2.5 h-auto rounded-lg shadow-lg disabled:opacity-50"
          >
            {isGenerating ? (
              <>
                <div className="animate-spin h-5 w-5 mr-3">
                  <Music className="h-5 w-5" />
                </div>
                Making your sound...
              </>
            ) : (
              <>
                <Sparkles className="h-5 w-5 mr-3" />
                Make It Happen ✨
              </>
            )}
          </Button>
        </div>
      </Card>

      {/* Loading Layer */}
      {isGenerating && (
        <AudioPlayer layerName="Generating..." isLoading={true} />
      )}

      {/* Created Layers */}
      <div className="space-y-4">
        {layers.map((layer) => (
          <AudioPlayer
            key={layer.id}
            layerName={layer.name}
            isPlaying={layer.isPlaying}
            onPlayPause={() => toggleLayerPlayback(layer.id)}
          />
        ))}
      </div>

      {/* Collaboration CTA - Mobile optimized */}
      {layers.length >= 2 && (
        <Card className="border-accent/20 bg-accent/5 p-5">
          <div className="text-center space-y-4">
            <div className="flex justify-center">
              <div className="w-14 h-14 rounded-full bg-accent/20 flex items-center justify-center">
                <Mic className="h-7 w-7 text-accent" />
              </div>
            </div>
            <h3 className="text-lg font-semibold leading-tight">
              🔥 This is fire!
            </h3>
            <p className="text-muted-foreground text-sm leading-relaxed px-2">
              Your track is sounding amazing! Ready to share it with the world
              or get a friend to join in?
            </p>
            <div className="space-y-3 pt-2">
              <Button
                variant="outline"
                className="w-full border-accent/20 hover:border-accent/50 active:scale-[0.98] transition-transform p-2.5 h-auto text-xs"
              >
                <span className="mr-2">📱</span>
                Share Your Track
              </Button>
              <Button className="w-full gradient-primary border-0 active:scale-[0.98] transition-transform p-2.5 h-auto font-semibold text-xs">
                <span className="mr-2">👯</span>
                Invite a Friend
              </Button>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}
