import Layout from "@/components/Layout";
import { Card } from "@/components/ui/card";
import { User, Music, Users, Award } from "lucide-react";

export default function Profile() {
  return (
    <Layout>
      <div className="w-full px-3 py-3 space-y-3 min-h-full">
        <Card className="gradient-card p-3 border-border text-center">
          <div className="w-16 h-16 rounded-full gradient-primary mx-auto mb-3 flex items-center justify-center">
            <User className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-lg font-bold mb-2">Artist Profile</h1>
          <p className="text-muted-foreground text-xs mb-4 leading-relaxed px-2">
            Your musical identity and collaboration history
          </p>

          <div className="grid grid-cols-3 gap-3 mt-4">
            <div className="text-center">
              <div className="w-12 h-12 rounded-lg bg-primary/20 mx-auto mb-2 flex items-center justify-center">
                <Music className="h-6 w-6 text-primary" />
              </div>
              <h3 className="font-medium text-xs">Top Tracks</h3>
              <p className="text-xs text-muted-foreground">Coming Soon</p>
            </div>

            <div className="text-center">
              <div className="w-12 h-12 rounded-lg bg-accent/20 mx-auto mb-2 flex items-center justify-center">
                <Users className="h-6 w-6 text-accent" />
              </div>
              <h3 className="font-medium text-xs">Collaborations</h3>
              <p className="text-xs text-muted-foreground">Coming Soon</p>
            </div>

            <div className="text-center">
              <div className="w-12 h-12 rounded-lg bg-blue-500/20 mx-auto mb-2 flex items-center justify-center">
                <Award className="h-6 w-6 text-blue-400" />
              </div>
              <h3 className="font-medium text-xs">Achievements</h3>
              <p className="text-xs text-muted-foreground">Coming Soon</p>
            </div>
          </div>
        </Card>
      </div>
    </Layout>
  );
}
