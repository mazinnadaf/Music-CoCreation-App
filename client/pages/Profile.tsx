import Layout from "@/components/Layout";
import { Card } from "@/components/ui/card";
import { User, Music, Users, Award } from "lucide-react";

export default function Profile() {
  return (
    <Layout>
      <div className="min-h-screen py-8">
        <div className="max-w-4xl mx-auto p-6 space-y-6">
          <Card className="gradient-card p-8 border-border text-center">
            <div className="w-24 h-24 rounded-full gradient-primary mx-auto mb-4 flex items-center justify-center">
              <User className="h-12 w-12 text-white" />
            </div>
            <h1 className="text-2xl font-bold mb-2">Artist Profile</h1>
            <p className="text-muted-foreground mb-6">
              Your musical identity and collaboration history
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
              <div className="text-center">
                <div className="w-16 h-16 rounded-lg bg-primary/20 mx-auto mb-3 flex items-center justify-center">
                  <Music className="h-8 w-8 text-primary" />
                </div>
                <h3 className="font-semibold">Top Tracks</h3>
                <p className="text-sm text-muted-foreground">Coming Soon</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 rounded-lg bg-accent/20 mx-auto mb-3 flex items-center justify-center">
                  <Users className="h-8 w-8 text-accent" />
                </div>
                <h3 className="font-semibold">Collaborations</h3>
                <p className="text-sm text-muted-foreground">Coming Soon</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 rounded-lg bg-blue-500/20 mx-auto mb-3 flex items-center justify-center">
                  <Award className="h-8 w-8 text-blue-400" />
                </div>
                <h3 className="font-semibold">Achievements</h3>
                <p className="text-sm text-muted-foreground">Coming Soon</p>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
