"use client"

import { useRouter } from "next/navigation"
import { useState } from "react"

import {
  ActionButton,
  FormActions,
  FormField,
  FormFieldSet,
  FormRow,
  PageHeader,
  PageLayout,
} from "@/components/composed"

// ---------------------------------------------------------------------------
// Option data
// ---------------------------------------------------------------------------

const advertiserOptions = [
  { label: "Select advertiser", value: "" },
  { label: "Acme Corp", value: "acme" },
  { label: "Globex Inc", value: "globex" },
  { label: "Initech", value: "initech" },
]

const mediaOptions = [
  { label: "Select media", value: "" },
  { label: "Google Ads", value: "google" },
  { label: "Meta Ads", value: "meta" },
  { label: "Naver", value: "naver" },
  { label: "Kakao", value: "kakao" },
]

const regionOptions = [
  { label: "Select region", value: "" },
  { label: "South Korea", value: "kr" },
  { label: "United States", value: "us" },
  { label: "Japan", value: "jp" },
  { label: "Global", value: "global" },
]

// ---------------------------------------------------------------------------
// Page Component
// ---------------------------------------------------------------------------

export default function CampaignFormPage() {
  const router = useRouter()
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleCancel = () => {
    router.back()
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsSubmitting(true)

    const formData = new FormData(e.currentTarget)
    const payload = Object.fromEntries(formData.entries())

    // TODO: wire up API call
    console.log("submit", payload)

    setIsSubmitting(false)
    router.push("/campaigns")
  }

  return (
    <PageLayout>
      <PageHeader title="Create Campaign" backHref="/campaigns" />

      <form onSubmit={handleSubmit}>
        {/* ---- Basic Info ---- */}
        <FormFieldSet legend="Basic Info">
          <FormRow cols={2}>
            <FormField label="Campaign Name" required>
              <Input name="name" placeholder="Enter campaign name" />
            </FormField>
            <FormField label="Advertiser" required>
              <Select name="advertiser" options={advertiserOptions} />
            </FormField>
          </FormRow>
          <FormRow cols={2}>
            <FormField label="Media" required>
              <Select name="media" options={mediaOptions} />
            </FormField>
            <FormField label="Date Range">
              <DateRangePicker name="dateRange" />
            </FormField>
          </FormRow>
        </FormFieldSet>

        {/* ---- Budget ---- */}
        <FormFieldSet legend="Budget">
          <FormRow cols={2}>
            <FormField label="Daily Budget" description="Maximum spend per day">
              <Input
                name="dailyBudget"
                type="number"
                min={0}
                placeholder="0"
              />
            </FormField>
            <FormField label="Total Budget" description="Lifetime campaign budget">
              <Input
                name="totalBudget"
                type="number"
                min={0}
                placeholder="0"
              />
            </FormField>
          </FormRow>
        </FormFieldSet>

        {/* ---- Targeting ---- */}
        <FormFieldSet legend="Targeting">
          <FormRow cols={2}>
            <FormField label="Region">
              <Select name="region" options={regionOptions} />
            </FormField>
            <FormField label="Interests" description="Comma-separated keywords">
              <Input name="interests" placeholder="e.g. tech, sports, fashion" />
            </FormField>
          </FormRow>
          <FormRow cols={2}>
            <FormField label="Min Age">
              <Input name="ageMin" type="number" min={13} max={65} placeholder="13" />
            </FormField>
            <FormField label="Max Age">
              <Input name="ageMax" type="number" min={13} max={65} placeholder="65" />
            </FormField>
          </FormRow>
        </FormFieldSet>

        {/* ---- Actions ---- */}
        <FormActions>
          <ActionButton variant="outline" onClick={handleCancel}>
            Cancel
          </ActionButton>
          <ActionButton type="submit" disabled={isSubmitting}>
            {isSubmitting ? "Saving..." : "Save"}
          </ActionButton>
        </FormActions>
      </form>
    </PageLayout>
  )
}
