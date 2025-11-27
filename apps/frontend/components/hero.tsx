"use client"

import { Button } from "@/components/ui/button"
import { ArrowDown, Linkedin, Github, Mail, Cloud, Loader2, Users, Activity } from "lucide-react"
import { motion } from "framer-motion"
import { useState, useEffect } from "react"

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api.selffish234.cloud';

interface StatusData {
  service: string;
  region: string;
  status: string;
  message?: string;
}

interface CounterData {
  visits: number;
  requests: number;
}

export function Hero() {
  const [statusData, setStatusData] = useState<StatusData | null>(null);
  const [counterData, setCounterData] = useState<CounterData | null>(null);
  const [loading, setLoading] = useState(true);

  // 데이터 가져오기 함수
  const fetchData = async () => {
    try {
      // 1. 상태 가져오기
      const statusRes = await fetch(`${API_URL}/api/status`);
      const statusJson = await statusRes.json();
      setStatusData(statusJson);

      // 2. 카운터 가져오기
      const counterRes = await fetch(`${API_URL}/api/counter`);
      const counterJson = await counterRes.json();
      setCounterData(counterJson);
      
      setLoading(false);
    } catch (err) {
      console.error(err);
      setStatusData({ service: "Unknown", region: "Unknown", status: "Error", message: "API Error" });
      setLoading(false);
    }
  };

  // 방문자 수 증가 함수
  const handleIncrement = async () => {
    try {
      await fetch(`${API_URL}/api/counter/increment`, { method: 'POST' });
      fetchData(); // 데이터 다시 불러오기 (새로고침 효과)
    } catch (err) {
      console.error("Increment failed", err);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // 상태 UI 렌더링
  let statusContent;
  if (loading) {
    statusContent = (
      <div className="flex items-center justify-center gap-2 mb-4 text-muted-foreground">
        <Loader2 className="h-5 w-5 animate-spin" />
        <p className="text-sm font-medium">상태 확인 중...</p>
      </div>
    );
  } else if (statusData?.status === "Active") {
    statusContent = (
      <div className="flex flex-col gap-3 mb-8">
        {/* 클러스터 상태 */}
        <div className="flex items-center justify-center gap-2 text-green-600 bg-green-100/50 py-1 px-3 rounded-full w-fit mx-auto">
          <Cloud className="h-5 w-5" />
          <p className="text-sm font-medium">
            {statusData.region} | {statusData.status}
          </p>
        </div>

        {/* 카운터 통계 (새로 추가된 부분) */}
        {counterData && (
          <div className="flex justify-center gap-4 text-sm font-medium text-muted-foreground">
            <div className="flex items-center gap-1 bg-secondary/50 px-3 py-1 rounded-md">
              <Users className="h-4 w-4" />
              <span>방문자: {counterData.visits}</span>
            </div>
            <div className="flex items-center gap-1 bg-secondary/50 px-3 py-1 rounded-md">
              <Activity className="h-4 w-4" />
              <span>API 요청: {counterData.requests}</span>
            </div>
          </div>
        )}
      </div>
    );
  } else {
    statusContent = <div className="text-red-500 mb-4">API 연결 실패</div>;
  }

  return (
    <section className="min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8 pt-16 relative">
      <div className="max-w-4xl mx-auto text-center">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8 }}>
          
          {/* 상태 및 카운터 표시 */}
          {statusContent}

          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold text-foreground mb-6 text-balance">
            Cloud System Engineer
          </h1>
          <p className="text-xl sm:text-2xl text-muted-foreground mb-4">김서준 (Seojoon Kim)</p>
          
          <div className="flex flex-wrap items-center justify-center gap-4 mb-12">
            {/* 방문자 증가 버튼 (새로 추가됨) */}
            <Button size="lg" onClick={handleIncrement} className="bg-blue-600 hover:bg-blue-700">
              방문자 수 올리기 (+1)
            </Button>
            <Button size="lg" variant="outline" asChild>
              <a href="#projects">프로젝트 보기</a>
            </Button>
          </div>

          <div className="flex items-center justify-center gap-6">
            <a href="https://github.com/selffish234" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-primary transition-colors">
              <Github className="h-6 w-6" />
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
