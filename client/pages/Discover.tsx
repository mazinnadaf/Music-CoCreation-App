import Layout from "@/components/Layout";
import DiscoveryFeed from "@/components/DiscoveryFeed";

export default function Discover() {
  return (
    <Layout>
      <div className="min-h-screen py-8">
        <DiscoveryFeed />
      </div>
    </Layout>
  );
}
