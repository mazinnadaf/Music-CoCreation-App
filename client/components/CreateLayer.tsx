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
    <div className="max-w-4xl mx-auto p-6 space-y-8">
      {/* Header */}
      <div className="text-center space-y-4">
        <h1 className="text-4xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
          Create Your Next Hit
        </h1>
        <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
          Start with a single layer and build your masterpiece. No experience
          needed - just describe what you hear in your head.
        </p>
      </div>

      {/* Creation Interface */}
      <Card className="gradient-card p-6 border-border">
        <div className="space-y-4">
          <div className="flex items-center space-x-2 text-sm text-muted-foreground">
            <Sparkles className="h-4 w-4" />
            <span>Describe the sound you want to create</span>
          </div>

          <Textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="a dreamy synth melody inspired by Tame Impala, 120 BPM"
            className="min-h-[100px] text-lg bg-background/50 border-border focus:border-primary/50"
          />

          {/* Suggested Prompts */}
          {showSuggestion && layers.length === 0 && (
            <div className="flex flex-wrap gap-2">
              <span className="text-sm text-muted-foreground">Try:</span>
              {SUGGESTED_PROMPTS.slice(1, 4).map((suggestion, i) => (
                <Button
                  key={i}
                  variant="outline"
                  size="sm"
                  onClick={() => suggestPrompt(suggestion)}
                  className="text-xs border-border hover:border-primary/50"
                >
                  {suggestion}
                </Button>
              ))}
            </div>
          )}

          {showSuggestion && layers.length === 1 && (
            <div className="bg-accent/10 border border-accent/20 rounded-lg p-4">
              <div className="flex items-center space-x-2 text-accent mb-2">
                <Zap className="h-4 w-4" />
                <span className="font-medium">
                  Great start! Every song needs rhythm.
                </span>
              </div>
              <p className="text-sm text-muted-foreground mb-3">
                Try adding some drums to give your melody a foundation:
              </p>
              <Button
                variant="outline"
                size="sm"
                onClick={() => suggestPrompt(SUGGESTED_PROMPTS[1])}
                className="border-accent/20 hover:border-accent/50 text-accent"
              >
                {SUGGESTED_PROMPTS[1]}
              </Button>
            </div>
          )}

          <Button
            onClick={handleCreateLayer}
            disabled={!prompt.trim() || isGenerating}
            size="lg"
            className="w-full gradient-primary border-0 hover:scale-[1.02] transition-transform text-lg py-6"
          >
            {isGenerating ? (
              <>
                <div className="animate-spin h-5 w-5 mr-2">
                  <Music className="h-5 w-5" />
                </div>
                Creating your layer...
              </>
            ) : (
              <>
                <Sparkles className="h-5 w-5 mr-2" />
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

      {/* Collaboration CTA */}
      {layers.length >= 2 && (
        <Card className="border-accent/20 bg-accent/5 p-6">
          <div className="text-center space-y-4">
            <div className="flex justify-center">
              <div className="w-12 h-12 rounded-full bg-accent/20 flex items-center justify-center">
                <Mic className="h-6 w-6 text-accent" />
              </div>
            </div>
            <h3 className="text-xl font-semibold">This is sounding great!</h3>
            <p className="text-muted-foreground">
              Ready to take it to the next level? Share your loop or invite a
              friend to collaborate.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <Button
                variant="outline"
                className="border-accent/20 hover:border-accent/50"
              >
                Share Loop
              </Button>
              <Button className="gradient-primary border-0">
                Invite Collaborator
              </Button>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}
