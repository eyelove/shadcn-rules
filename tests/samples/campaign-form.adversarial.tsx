// Adversarial sample: Campaign Form with intentional rule violations
// Expected violations: FORB-01, FORB-02, FORB-03, FORB-05, FMT-02, TOKEN-01

export default function CampaignFormPage() {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log("Form submitted")
  }

  return (
    <div className="flex flex-col gap-6 p-6">
      {/* Page Header */}
      <div className="flex items-center gap-4">
        <button className="bg-gray-100 p-2 rounded-lg" onClick={() => console.log("back")}>
          Back
        </button>
        <h1 className="text-2xl font-semibold">Create Campaign</h1>
      </div>

      {/* VIOLATION FORB-03: raw div as card substitute instead of Card */}
      <div className="rounded-lg border bg-white p-6">
        <h2 className="text-lg font-semibold mb-2">Campaign Details</h2>
        <p className="text-sm text-gray-500 mb-6">Fill in the details for your new campaign.</p>

        <form onSubmit={handleSubmit}>
          {/* Section 1 — VIOLATION FORB-03: another div-card for section */}
          <div className="rounded-lg border p-4 mb-6" style={{ backgroundColor: "#fafafa" }}>
            <h3 className="font-medium mb-4">Basic Info</h3>

            {/* VIOLATION FORB-05: bare input without Field wrapper */}
            {/* VIOLATION FIELD-02: bare <label> */}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label htmlFor="name" className="text-sm font-medium">
                  Campaign Name <span style={{ color: "red" }}>*</span>
                </label>
                <input
                  id="name"
                  name="name"
                  className="border rounded-md px-3 py-2 w-full mt-1"
                  placeholder="Enter campaign name"
                />
              </div>
              <div>
                <label htmlFor="status" className="text-sm font-medium">Status</label>
                <select
                  id="status"
                  name="status"
                  className="border rounded-md px-3 py-2 w-full mt-1"
                >
                  <option value="active">Active</option>
                  <option value="draft">Draft</option>
                  <option value="paused">Paused</option>
                </select>
              </div>
            </div>

            <div className="mt-4">
              <label htmlFor="description" className="text-sm font-medium">Description</label>
              <textarea
                id="description"
                name="description"
                className="border rounded-md px-3 py-2 w-full mt-1"
                placeholder="Optional description"
                rows={3}
              />
            </div>
          </div>

          {/* Section 2 — VIOLATION FORB-01: inline styles for spacing */}
          <div className="rounded-lg border p-4" style={{ marginTop: "24px", backgroundColor: "#fafafa" }}>
            <h3 className="font-medium mb-4">Budget & Targeting</h3>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label htmlFor="budget" className="text-sm font-medium">Daily Budget</label>
                {/* VIOLATION FMT-02: hardcoded currency symbol */}
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-sm font-medium">$</span>
                  <input
                    id="budget"
                    name="budget"
                    type="number"
                    className="border rounded-md px-3 py-2 w-full"
                    placeholder="0"
                  />
                </div>
              </div>
              <div>
                <label htmlFor="region" className="text-sm font-medium">Region</label>
                <select
                  id="region"
                  name="region"
                  className="border rounded-md px-3 py-2 w-full mt-1"
                >
                  <option value="us">United States</option>
                  <option value="eu">Europe</option>
                  <option value="apac">Asia Pacific</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 mt-4">
              <div>
                <label htmlFor="startDate" className="text-sm font-medium">Start Date</label>
                <input
                  id="startDate"
                  name="startDate"
                  type="date"
                  className="border rounded-md px-3 py-2 w-full mt-1"
                />
              </div>
              <div>
                <label htmlFor="endDate" className="text-sm font-medium">End Date</label>
                <input
                  id="endDate"
                  name="endDate"
                  type="date"
                  className="border rounded-md px-3 py-2 w-full mt-1"
                />
              </div>
            </div>
          </div>

          {/* VIOLATION: Submit before Cancel (reversed order) */}
          {/* VIOLATION FORB-02: bg-blue-600 hardcoded color */}
          <div className="flex gap-4 mt-6" style={{ justifyContent: "flex-end" }}>
            <button
              type="submit"
              className="bg-blue-600 text-white px-4 py-2 rounded-lg"
            >
              Save
            </button>
            <button
              type="button"
              className="border border-gray-300 px-4 py-2 rounded-lg"
              onClick={() => console.log("cancel")}
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
