"use client"

import { Button } from "@/components/ui/button"
import { ArrowDown, Linkedin, Github, Mail, Cloud, Loader2 } from "lucide-react"
import { motion } from "framer-motion"
import { useState, useEffect } from "react"

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api.selffish234.cloud';

interface StatusData {
  service: string;
  region: string;
  status: string;
  message?: string;
}

export function Hero() {
  const [statusData, setStatusData] = useState<StatusData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${API_URL}/api/status`)
      .then((res) => {
        if (!res.ok) throw new Error("Network response was not ok");
        return res.json();
      })
      .then((data) => {
        setStatusData(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to fetch status:", err);
        setStatusData({ service: "Unknown", region: "Unknown", status: "Error", message: "API Connection Failed" });
        setLoading(false);
      });
  }, []);

  // 상태에 따른 UI 결정
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
      <div className="flex items-center justify-center gap-2 mb-4 text-green-600 bg-green-100/50 py-1 px-3 rounded-full w-fit mx-auto">
        <Cloud className="h-5 w-5" />
        <p className="text-sm font-medium">
          클러스터 정상 작동 (Active) | Region: {statusData.region}
        </p>
      </div>
    );
  } else {
    statusContent = (
      <div className="flex items-center justify-center gap-2 mb-4 text-red-500">
        <Cloud className="h-5 w-5" />
        <p className="text-sm font-medium">
          백엔드 연결 실패 ({statusData?.message})
        </p>
      </div>
    );
  }

  return (
    <section className="min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8 pt-16 relative">
      <div className="max-w-4xl mx-auto text-center">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8 }}>
          
          {/* 동적 상태 표시 영역 */}
          {statusContent}

          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold text-foreground mb-6 text-balance">
            Cloud System Engineer
          </h1>
          <p className="text-xl sm:text-2xl text-muted-foreground mb-4">김서준 (Seojoon Kim)</p>
          
          <div className="flex flex-wrap items-center justify-center gap-4 mb-12">
            <Button size="lg" asChild><a href="#contact">연락하기</a></Button>
            <Button size="lg" variant="outline" asChild><a href="#projects">프로젝트 보기</a></Button>
          </div>

          <div className="flex items-center justify-center gap-6">
            <a href="https://www.linkedin.com/in/selffish234" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-primary transition-colors">
              <Linkedin className="h-6 w-6" />
            </a>
            <a href="https://github.com/selffish234" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-primary transition-colors">
              <Github className="h-6 w-6" />
            </a>
            <a href="#contact" className="text-muted-foreground hover:text-primary transition-colors">
              <Mail className="h-6 w-6" />
            </a>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1, duration: 1 }}
          className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
        >
          <a href="#about" className="text-muted-foreground hover:text-foreground transition-colors">
            <ArrowDown className="h-6 w-6 animate-bounce" />
          </a>
        </motion.div>
      </div>
    </section>
  )
}
