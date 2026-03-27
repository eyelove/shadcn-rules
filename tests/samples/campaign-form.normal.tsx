// Sample: Form / Settings Page — PAGE-03
// Rewritten for 2-tier rule system (shadcn primitives + Field system).
// Rules applied: page-templates.md (PAGE-03), fields.md (FIELD-01–03),
//                cards.md (CARD-04), components.md (import rules)

import { ArrowLeftIcon } from "lucide-react"
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import {
  Field,
  FieldLabel,
  FieldSet,
  FieldLegend,
  FieldGroup,
  FieldDescription,
  FieldSeparator,
} from "@/components/ui/field"

export default function CampaignFormPage() {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log("Form submitted")
  }

  const handleCancel = () => {
    console.log("Cancel — navigate back to /campaigns")
  }

  return (
    <div className="flex flex-col gap-6 p-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <a href="/campaigns">
            <ArrowLeftIcon className="h-4 w-4" />
          </a>
        </Button>
        <h1 className="text-2xl font-semibold">Create Campaign</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Campaign Details</CardTitle>
          <CardDescription>
            Fill in the details for your new campaign.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form id="form-campaign" onSubmit={handleSubmit}>
            <FieldGroup>
              <FieldSet>
                <FieldLegend>Basic Info</FieldLegend>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <Field>
                    <FieldLabel htmlFor="name">Campaign Name</FieldLabel>
                    <Input
                      id="name"
                      name="name"
                      placeholder="Enter campaign name"
                    />
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="status">Status</FieldLabel>
                    <Select name="status">
                      <SelectTrigger id="status">
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="draft">Draft</SelectItem>
                        <SelectItem value="active">Active</SelectItem>
                        <SelectItem value="paused">Paused</SelectItem>
                      </SelectContent>
                    </Select>
                  </Field>
                </div>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <Field>
                    <FieldLabel htmlFor="objective">Objective</FieldLabel>
                    <Select name="objective">
                      <SelectTrigger id="objective">
                        <SelectValue placeholder="Select objective" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="awareness">
                          Brand Awareness
                        </SelectItem>
                        <SelectItem value="leads">Lead Generation</SelectItem>
                        <SelectItem value="conversions">Conversions</SelectItem>
                        <SelectItem value="traffic">Traffic</SelectItem>
                      </SelectContent>
                    </Select>
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="channel">Channel</FieldLabel>
                    <Select name="channel">
                      <SelectTrigger id="channel">
                        <SelectValue placeholder="Select channel" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="search">Search</SelectItem>
                        <SelectItem value="display">Display</SelectItem>
                        <SelectItem value="social">Social</SelectItem>
                        <SelectItem value="video">Video</SelectItem>
                      </SelectContent>
                    </Select>
                  </Field>
                </div>
                <Field>
                  <FieldLabel htmlFor="description">Description</FieldLabel>
                  <Textarea
                    id="description"
                    name="description"
                    placeholder="Enter a short description..."
                  />
                  <FieldDescription>
                    Optional — describe the campaign goal
                  </FieldDescription>
                </Field>
              </FieldSet>

              <FieldSeparator />

              <FieldSet>
                <FieldLegend>Budget & Schedule</FieldLegend>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <Field>
                    <FieldLabel htmlFor="budget">Total Budget</FieldLabel>
                    <Input
                      id="budget"
                      name="budget"
                      placeholder="e.g. 10000"
                    />
                    <FieldDescription>
                      Maximum lifetime spend in USD
                    </FieldDescription>
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="dailyCap">Daily Cap</FieldLabel>
                    <Input
                      id="dailyCap"
                      name="dailyCap"
                      placeholder="e.g. 500"
                    />
                    <FieldDescription>
                      Maximum daily spend in USD
                    </FieldDescription>
                  </Field>
                </div>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <Field>
                    <FieldLabel htmlFor="flightDates">Flight Dates</FieldLabel>
                    <Input
                      id="flightDates"
                      name="flightDates"
                      type="date"
                      placeholder="Select date range"
                    />
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="region">Target Region</FieldLabel>
                    <Select name="region">
                      <SelectTrigger id="region">
                        <SelectValue placeholder="Select region" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="global">Global</SelectItem>
                        <SelectItem value="na">North America</SelectItem>
                        <SelectItem value="eu">Europe</SelectItem>
                        <SelectItem value="apac">Asia Pacific</SelectItem>
                      </SelectContent>
                    </Select>
                  </Field>
                </div>
              </FieldSet>
            </FieldGroup>
          </form>
        </CardContent>
        <CardFooter className="border-t">
          <Button variant="outline" type="button" onClick={handleCancel}>
            Cancel
          </Button>
          <Button type="submit" form="form-campaign">
            Save
          </Button>
        </CardFooter>
      </Card>
    </div>
  )
}
