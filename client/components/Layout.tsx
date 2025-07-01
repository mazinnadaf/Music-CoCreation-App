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
    { name: "Create", href: "/", icon: Home },
    { name: "Discover", href: "/discover", icon: Search },
    { name: "Profile", href: "/profile", icon: User },
  ];

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile App Container */}
      <div className="max-w-sm mx-auto bg-background min-h-screen relative overflow-hidden border-x border-border shadow-2xl">
        {/* Mobile Header - Simplified */}
        <header className="border-b border-border bg-card/80 backdrop-blur-md sticky top-0 z-50 safe-area-top">
          <div className="px-4 py-3">
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
        <main className="flex-1 pb-16">{children}</main>

        {/* Mobile Bottom Navigation - Contained within app frame */}
        <nav className="absolute bottom-0 left-0 right-0 bg-card/95 backdrop-blur-lg border-t border-border safe-area-bottom z-50">
          <div className="flex justify-around items-center py-2 px-3">
            {navigation.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.href;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`flex flex-col items-center justify-center py-2 px-2 rounded-lg transition-all duration-200 active:scale-95 ${
                    isActive
                      ? "text-primary bg-primary/10"
                      : "text-muted-foreground active:bg-muted/20"
                  }`}
                >
                  <Icon
                    className={`h-5 w-5 mb-1 ${isActive ? "animate-pulse-slow" : ""}`}
                  />
                  <span className="text-xs font-medium">{item.name}</span>
                </Link>
              );
            })}

            {/* Floating Action Button */}
            <Button
              size="sm"
              className="gradient-primary border-0 rounded-full w-10 h-10 p-0 shadow-lg hover:shadow-xl transition-all duration-200 active:scale-95"
            >
              <Plus className="h-4 w-4" />
            </Button>
          </div>
        </nav>
      </div>
    </div>
  );
}
