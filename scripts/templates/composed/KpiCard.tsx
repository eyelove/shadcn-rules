import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardAction,
  CardFooter,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

interface KpiCardProps {
  label: string
  value: string
  delta: string
  deltaPositive?: boolean
  footerText?: string
}

export function KpiCard({ label, value, delta, deltaPositive, footerText }: KpiCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardDescription>{label}</CardDescription>
        <CardTitle className="text-2xl font-semibold tabular-nums">
          {value}
        </CardTitle>
        <CardAction>
          <Badge variant="outline" className={deltaPositive ? "text-[--kpi-positive]" : "text-[--kpi-negative]"}>
            {delta}
          </Badge>
        </CardAction>
      </CardHeader>
      {footerText && (
        <CardFooter className="text-muted-foreground text-sm">
          {footerText}
        </CardFooter>
      )}
    </Card>
  )
}
