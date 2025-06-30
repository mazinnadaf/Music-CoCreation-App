import { useLocation, Link } from "react-router-dom";
import { useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Music, Home } from "lucide-react";

const NotFound = () => {
  const location = useLocation();

  useEffect(() => {
    console.error(
      "404 Error: User attempted to access non-existent route:",
      location.pathname,
    );
  }, [location.pathname]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-6">
      <Card className="gradient-card p-8 border-border text-center max-w-md">
        <div className="w-16 h-16 rounded-lg gradient-primary mx-auto mb-4 flex items-center justify-center">
          <Music className="h-8 w-8 text-white" />
        </div>
        <h1 className="text-4xl font-bold mb-2 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
          404
        </h1>
        <h2 className="text-xl font-semibold mb-2">Track Not Found</h2>
        <p className="text-muted-foreground mb-6">
          The page you're looking for seems to have gone off-beat.
        </p>
        <Button asChild className="gradient-primary border-0">
          <Link to="/">
            <Home className="h-4 w-4 mr-2" />
            Back to Studio
          </Link>
        </Button>
      </Card>
    </div>
  );
};

export default NotFound;
