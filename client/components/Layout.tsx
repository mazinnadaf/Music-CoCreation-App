import { ReactNode } from "react";
import { Link, useLocation } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Music, Home, Search, User, Plus } from "lucide-react";

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const location = useLocation();

  const navigation = [
    { name: "Discover", href: "/discover", icon: Search },
    { name: "Profile", href: "/profile", icon: User },
  ];

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile App Container */}
      <div className="max-w-sm mx-auto bg-background h-[750px] relative overflow-hidden border-x border-border shadow-2xl flex flex-col">
        {/* Mobile Header - Simplified */}
        <header className="border-b border-border bg-card/80 backdrop-blur-md sticky top-0 z-50 safe-area-top">
          <div className="px-4 py-2">
            <div className="flex items-center justify-center">
              {/* Centered Logo for Mobile */}
              <Link to="/" className="flex items-center space-x-2">
                <div className="w-7 h-7 rounded-lg gradient-primary flex items-center justify-center">
                  <Music className="h-4 w-4 text-white" />
                </div>
                <span className="text-lg font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
                  SyncFlow
                </span>
              </Link>
            </div>
          </div>
        </header>

        {/* Main Content with mobile padding */}
        <main className="flex-1 overflow-y-auto">{children}</main>

        {/* Mobile Bottom Navigation - Contained within app frame */}
        <nav className="flex-shrink-0 bg-card/95 backdrop-blur-lg border-t border-border safe-area-bottom z-50">
          <div className="flex items-center justify-between py-1.5 px-6">
            {/* Discover Tab */}
            <Link
              to="/discover"
              className={`flex flex-col items-center justify-center py-2 px-3 rounded-lg transition-all duration-200 active:scale-95 ${
                location.pathname === "/discover"
                  ? "text-primary bg-primary/10"
                  : "text-muted-foreground active:bg-muted/20"
              }`}
            >
              <Search
                className={`h-5 w-5 mb-1 ${location.pathname === "/discover" ? "animate-pulse-slow" : ""}`}
              />
              <span className="text-xs font-medium">Discover</span>
            </Link>

            {/* Central Create Button */}
            <Link to="/">
              <Button
                size="sm"
                className={`gradient-primary border-0 rounded-full w-12 h-12 p-0 shadow-lg hover:shadow-xl transition-all duration-200 active:scale-95 ${
                  location.pathname === "/" ? "ring-2 ring-primary/50" : ""
                }`}
              >
                <Plus className="h-5 w-5" />
              </Button>
            </Link>

            {/* Profile Tab */}
            <Link
              to="/profile"
              className={`flex flex-col items-center justify-center py-2 px-3 rounded-lg transition-all duration-200 active:scale-95 ${
                location.pathname === "/profile"
                  ? "text-primary bg-primary/10"
                  : "text-muted-foreground active:bg-muted/20"
              }`}
            >
              <User
                className={`h-5 w-5 mb-1 ${location.pathname === "/profile" ? "animate-pulse-slow" : ""}`}
              />
              <span className="text-xs font-medium">Profile</span>
            </Link>
          </div>
        </nav>
      </div>
    </div>
  );
}
