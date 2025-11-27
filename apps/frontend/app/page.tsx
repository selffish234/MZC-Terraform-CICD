import { Hero } from "@/components/hero"

// 환경 변수 처리 (빌드 시점에 주입됨)
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getPortfolioStatus() {
  try {
    const response = await fetch(`${API_URL}/api/status`, { cache: 'no-store' });
    if (!response.ok) return { status: "Error", message: "Fetch failed", region: "Unknown", service: "Unknown" };
    return await response.json();
  } catch (error) {
    return { status: "Error", message: "Connection failed", region: "Unknown", service: "Unknown" };
  }
}

export default async function Home() {
  const statusData = await getPortfolioStatus();
  return (
    <main className="min-h-screen bg-background">
      <Hero statusData={statusData} />
    </main>
  )
}
