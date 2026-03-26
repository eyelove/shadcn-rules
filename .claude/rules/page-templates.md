---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "pages/**/*.tsx"
---

# Page Skeleton Templates

Every page type has a canonical Composed component sequence. Follow it exactly — do not invent structure.
No `className` or `style={{}}` on any Composed component. No primitives from `@/components/ui/`.

## PAGE-01 — List Page

```tsx
// CORRECT — List Page
<PageLayout>
  <PageHeader title="[Entity] List" action={<ActionButton onClick={onCreate}>New [Entity]</ActionButton>} />
  <SearchBar
    filters={[
      { type: "text", key: "name", label: "[Entity] Name" },
      { type: "select", key: "status", label: "Status", options: statusOptions },
    ]}
    onSearch={handleSearch}
  />
  <DataTable columns={columns} data={rows} onRowClick={(row) => navigate(row.id)} emptyMessage="No [entities] found." />
</PageLayout>
// FORBIDDEN: Adding KpiCardGroup or ChartSection to a list page; nesting DataTable inside a div; custom layout wrappers around SearchBar.
```
// WHY: List pages expose filtered tabular data only. KPI and chart sections belong on Dashboard/Detail pages.

## PAGE-02 — Detail Page

```tsx
// CORRECT — Detail Page
<PageLayout>
  <PageHeader title="[Entity] Detail" backHref="/[entities]" action={<StatusBadge status={entity.status} />} />
  <KpiCardGroup cols={4} items={kpiItems} />
  <ChartSection cols={1} charts={[{ title: "Performance", chart: <MyChart /> }]} />
  <DataTable columns={columns} data={rows} onRowClick={(row) => navigate(row.id)} emptyMessage="No records found." />
</PageLayout>
// FORBIDDEN: Using TabGroup to wrap sections; omitting backHref on PageHeader; placing StatusBadge outside the action prop.
```
// WHY: Detail pages use a flat KPI → Chart → Table sequence. TabGroup fragments context and breaks the scan pattern.

## PAGE-03 — Form / Settings Page

```tsx
// CORRECT — Form Page
<PageLayout>
  <PageHeader title="Create [Entity]" backHref="/[entities]" />
  <form onSubmit={handleSubmit}>
    <FormFieldSet legend="Basic Info">
      <FormRow cols={2}>
        <FormField label="Name" required><Input name="name" /></FormField>
        <FormField label="Status"><Select name="status" options={opts} /></FormField>
      </FormRow>
    </FormFieldSet>
    <FormActions>
      <ActionButton variant="outline" onClick={handleCancel}>Cancel</ActionButton>
      <ActionButton type="submit">Save</ActionButton>
    </FormActions>
  </form>
</PageLayout>
// FORBIDDEN: FormActions inside FormFieldSet; Save button before Cancel button; omitting backHref on PageHeader for create/edit pages; raw HTML <input> or <div> layout.
```
// WHY: backHref is required on all create/edit forms. Cancel always precedes Save (dismissive before primary).

## PAGE-04 — Dashboard Overview Page

```tsx
// CORRECT — Dashboard Page
<PageLayout>
  <PageHeader title="Dashboard" subtitle="Overview of performance" action={<ActionButton onClick={onCreate}>New [Entity]</ActionButton>} />
  <KpiCardGroup cols={4} items={kpiItems} />
  <ChartSection cols={2} charts={[{ title: "Daily Spend", chart: <ChartA /> }, { title: "Channel Split", chart: <ChartB /> }]} />
  <DataTable columns={columns} data={rows} onRowClick={(row) => navigate(row.id)} emptyMessage="No recent records." />
</PageLayout>
// FORBIDDEN: ChartSection cols={1} on a dashboard (must be 2-column); omitting KpiCardGroup; placing DataTable before ChartSection.
```
// WHY: Dashboard always shows KPI summary first, then 2-column charts, then recent activity table.

---

For component Props contracts, see: @.claude/rules/component-interfaces.md
For form structure rules, see: @.claude/rules/forms.md
