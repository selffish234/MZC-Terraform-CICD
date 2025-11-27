"use client"
import { Button } from "@/components/ui/button"
import { Cloud } from "lucide-react"

interface HeroProps {
  statusData: {
    service: string;
    region: string;
    status: string;
    message?: string;
    env?: string;
  };
}

export function Hero({ statusData }: HeroProps) {
  const statusColor = statusData.status === "Active" ? "text-green-500" : "text-red-500";
  return (
    <section className="min-h-screen flex items-center justify-center pt-16">
      <div className="text-center">
        <div className="flex items-center justify-center gap-2 mb-4">
          <Cloud className={`h-5 w-5 ${statusColor}`} />
          <p className={`text-sm font-medium ${statusColor}`}>
            {statusData.status} | Env: {statusData.env}
          </p>
        </div>
        <h1 className="text-5xl font-bold mb-6">Cloud System Engineer</h1>
      </div>
    </section>
  )
}
