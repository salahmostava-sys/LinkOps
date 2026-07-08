# System Architecture Documentation

This document outlines the high-level architecture, data flows, and module dependencies for the Delivery Driver Management System (Muhimmat Altawseel). The system handles rider management, attendance, daily orders, and automated salary calculations using a modern React frontend and Supabase backend.

## 1. System Architecture Diagram

This diagram illustrates the high-level infrastructure of the system, showing how the frontend interacts with Supabase services, database, and external APIs.

```mermaid
flowchart TD
    User([User / Admin]) --> Frontend
    
    subgraph FrontendApp [Frontend]
        React[React + TypeScript App]
    end
    
    Frontend --> React
    React --> SupaAPI
    React --> SupaAuth
    React --> EdgeFunctions
    
    subgraph SupabaseBackend [Backend (Supabase)]
        SupaAuth[Supabase Auth]
        SupaAPI[Supabase API / PostgREST]
        EdgeFunctions[Edge Functions]
        SalaryEngine[Salary Engine]
        DB[(PostgreSQL Database)]
    end
    
    subgraph External [External Services]
        Groq[Groq Proxy / AI Insights]
    end
    
    SupaAPI --> DB
    SupaAuth --> DB
    EdgeFunctions --> SalaryEngine
    SalaryEngine --> DB
    EdgeFunctions --> Groq
```

---

## 2. Data Flow Diagram

This sequence diagram demonstrates the standard lifecycle of data moving from the user interface down to the database and back.

```mermaid
sequenceDiagram
    actor User
    participant App as React Frontend
    participant Supa as Supabase API
    participant DB as PostgreSQL Database
    
    User->>App: Interacts with UI (e.g., Save Orders)
    App->>Supa: API Request (HTTP / REST)
    Supa->>DB: Database Query / Mutation
    DB-->>Supa: Data Result
    Supa-->>App: JSON Response
    App-->>User: State Updated & UI Re-rendered
```

---

## 3. Module Dependencies

This graph shows the structural dependency chain within the React frontend, illustrating how pages, components, hooks, and services connect.

```mermaid
graph TD
    App[App / Router] --> Pages[Pages]
    Pages --> Components[UI Components]
    Pages --> Services[Services Layer]
    Components --> Hooks[Custom Hooks]
    Hooks --> Services
    Services --> SupaClient[Supabase Client]
    SupaClient --> Backend[(Supabase Backend)]
```

---

## 4. Feature Module Diagram (Orders Module)

A zoomed-in look at the **Orders Module**, showcasing the relationship between its visual components, state hooks, and API services.

```mermaid
graph TD
    OrdersPage[OrdersPage] --> useOrdersGridData[useOrdersGridData Hook]
    OrdersPage --> OrdersGridTable[OrdersGridTable]
    
    OrdersGridTable --> OrdersEmployeeRow[OrdersEmployeeRow]
    OrdersGridTable --> OrdersCellPopover[OrdersCellPopover]
    
    useOrdersGridData --> OrdersService[OrdersService]
    OrdersService --> Supabase[(Supabase Client)]
```

---

## 5. Salary Flow Diagram

This flowchart outlines the critical business logic path for calculating a rider's salary based on daily orders, platform configurations, and salary tiers/rules.

```mermaid
flowchart TD
    Orders[Daily Orders] --> DataAgg
    Apps[Platform / Apps Configuration] --> DataAgg
    Rules[Salary Rules & Tiers] --> Engine
    
    subgraph Engine [Salary Engine Processing]
        DataAgg[Data Aggregation] --> Calc[Calculation Logic]
        Calc --> Deductions[Deductions & Advances]
    end
    
    Deductions --> FinalSalary[Final Salary Result]
    FinalSalary --> DB[(PostgreSQL Database)]
    FinalSalary --> Payslip[Displayed in UI Payslip]
```
