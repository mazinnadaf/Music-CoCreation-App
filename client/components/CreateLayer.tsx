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
  "a dreamy synth melody inspired by Tame Impala, 120 BPM",
  "a punchy lo-fi drum beat",
  "smooth jazz bass line in F major",
  "ambient pad sounds with reverb",
  "uplifting acoustic guitar strumming",
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
    <div className="w-full px-4 py-6 space-y-6">
      {/* Header - Mobile optimized */}
      <div className="text-center space-y-3">
        <h1 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent leading-tight">
          Create Your Next Hit
        </h1>
        <p className="text-base text-muted-foreground px-2 leading-relaxed">
          Start with a single layer and build your masterpiece. No experience
          needed.
        </p>
      </div>

      {/* Creation Interface - Mobile optimized */}
      <Card className="gradient-card p-4 border-border">
        <div className="space-y-4">
          <div className="flex items-center space-x-2 text-sm text-muted-foreground">
            <Sparkles className="h-4 w-4" />
            <span>Describe the sound you want to create</span>
          </div>

          <Textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="a dreamy synth melody inspired by Tame Impala, 120 BPM"
            className="min-h-[120px] text-base leading-relaxed bg-background/50 border-border focus:border-primary/50 rounded-xl p-4 resize-none"
            style={{
              fontSize: "16px", // Prevent zoom on iOS
              lineHeight: "1.5",
            }}
          />

          {/* Suggested Prompts - Mobile stacked */}
          {showSuggestion && layers.length === 0 && (
            <div className="space-y-2">
              <span className="text-sm text-muted-foreground block">
                Try these:
              </span>
              <div className="grid gap-2">
                {SUGGESTED_PROMPTS.slice(1, 4).map((suggestion, i) => (
                  <Button
                    key={i}
                    variant="outline"
                    size="sm"
                    onClick={() => suggestPrompt(suggestion)}
                    className="text-sm p-3 h-auto text-left justify-start border-border hover:border-primary/50 active:scale-[0.98] transition-transform"
                  >
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
                  <Zap className="h-4 w-4 text-accent" />
                </div>
                <div className="space-y-2 flex-1">
                  <span className="font-medium text-accent block leading-tight">
                    Great start! Every song needs rhythm.
                  </span>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    Try adding some drums to give your melody a foundation:
                  </p>
                </div>
              </div>
              <Button
                variant="outline"
                onClick={() => suggestPrompt(SUGGESTED_PROMPTS[1])}
                className="w-full p-3 h-auto text-left justify-start border-accent/20 hover:border-accent/50 text-accent text-sm active:scale-[0.98] transition-transform"
              >
                {SUGGESTED_PROMPTS[1]}
              </Button>
            </div>
          )}

          <Button
            onClick={handleCreateLayer}
            disabled={!prompt.trim() || isGenerating}
            className="w-full gradient-primary border-0 active:scale-[0.98] transition-all duration-200 text-lg font-semibold py-4 h-auto rounded-xl shadow-lg disabled:opacity-50"
          >
            {isGenerating ? (
              <>
                <div className="animate-spin h-5 w-5 mr-3">
                  <Music className="h-5 w-5" />
                </div>
                Creating your layer...
              </>
            ) : (
              <>
                <Sparkles className="h-5 w-5 mr-3" />
                Create Layer
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
              This is sounding great!
            </h3>
            <p className="text-muted-foreground text-sm leading-relaxed px-2">
              Ready to take it to the next level? Share your loop or invite a
              friend to collaborate.
            </p>
            <div className="space-y-3 pt-2">
              <Button
                variant="outline"
                className="w-full border-accent/20 hover:border-accent/50 active:scale-[0.98] transition-transform p-3 h-auto"
              >
                Share Loop
              </Button>
              <Button className="w-full gradient-primary border-0 active:scale-[0.98] transition-transform p-3 h-auto font-semibold">
                Invite Collaborator
              </Button>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}
