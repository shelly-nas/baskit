# Baskit - Functional Design Document

## Document Information

- **Project Name:** Baskit
- **Document Version:** 1.0
- **Date:** September 14, 2025
- **Author:** Jelle van der Graaf
- **Status:** Draft

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Overview](#project-overview)
3. [Stakeholders](#stakeholders)
4. [User Stories & Use Cases](#user-stories--use-cases)
5. [Functional Requirements](#functional-requirements)
6. [Non-Functional Requirements](#non-functional-requirements)
7. [System Architecture](#system-architecture)
8. [Risk Analysis](#risk-analysis)

---

## 1. Executive Summary

Baskit is a comprehensive grocery shopping companion that aggregates real-time prices and discounts from all grocery stores in a user's area. With groceries being a significant household expense and essential need, Baskit addresses the critical challenge of helping consumers make informed decisions to maximize their savings. The platform analyzes user shopping lists against current store prices and promotions to recommend optimal shopping strategies.

The application goes beyond simple price comparison by offering route optimization, allowing users to choose between the most cost-effective shopping approach or the fastest route to complete their grocery shopping. By providing visibility into all available discounts and promotions across multiple retailers, Baskit empowers users to make strategic decisions that can significantly impact their household budgets.

Baskit is designed to serve every household, with particular focus on lower income to median income families where grocery savings can have the most meaningful financial impact. For these households, even modest percentage savings on groceries can translate to substantial monthly budget relief.

**Purpose:** Baskit is a smart grocery shopping companion that starts with excellent list management and adds intelligent price comparison and route optimization for premium users, helping them save money through strategic shopping decisions.

**Target Market:** Universal household appeal starting with anyone who makes grocery lists, with premium features targeting budget-conscious households seeking maximum grocery savings.

**Key Benefits:**

- **Smart List Management:** Intuitive grocery list creation with intelligent product suggestions (Free)
- **Price Intelligence:** Access to all local grocery store prices and discounts in one platform (Premium)
- **Route Optimization:** Choice between cheapest shopping route or fastest completion time (Premium)
- **Financial Impact:** Significant reduction in grocery expenses through strategic shopping decisions (Premium)

**Success Metrics:**

- **Average Savings per User:** Target $50-100+ monthly savings per active user
- **User Engagement:** 70%+ weekly active user rate among registered users
- **Market Coverage:** Integration with 80%+ of grocery stores in target markets

---

## 2. Project Overview

### 2.1 Purpose

Baskit starts by solving the basic problem of grocery list management - everyone needs to track what they want to buy, but current solutions are either too basic or too complex. Our core platform provides an excellent list-making experience that users will love even without price features.

Building on this foundation, Baskit addresses the advanced problem of missed savings opportunities in the Netherlands' sale-driven grocery market. Dutch consumers face relatively high standard pricing with frequent promotional sales across multiple supermarket chains. However, people cannot realistically track every sale happening across all stores, resulting in significant missed savings on essential purchases.

The problem is compounded by busy lifestyles - consumers need flexibility to balance price optimization against time efficiency. They want the option to either maximize savings by visiting multiple stores for the best deals, or minimize time by shopping at a single store with competitive overall pricing.

For premium users, Baskit provides the intelligence layer that makes strategic grocery shopping practical and accessible, while free users get excellent list management that forms the foundation of smart shopping.

### 2.2 Scope

**In Scope:**

**MVP (Free Tier):**

- **Intelligent Shopping Lists:** Creation, management, and habit tracking for recurring grocery items
- **Smart Product Search:** Basic product search with suggestions for building lists
- **List Sharing:** Basic shared lists for family collaboration
- **Offline Support:** Core list functionality works without internet

**Premium Features:**

- **Real-time Price Aggregation:** Continuous monitoring of prices across target Dutch supermarket chains
- **Discount and Promotion Tracking:** Comprehensive tracking of sales, weekly offers, and special promotions
- **Smart Product Matching:** AI-powered product matching that can map generic items (like "peanut butter") to specific brands and variations across stores
- **Route Optimization:** Dual-mode planning for either maximum savings (multi-store) or maximum efficiency (single-store)
- **Navigation Integration:** Store location services with integration to popular navigation apps
- **Grocery List Optimization:** Reordering items based on default store layout for efficient in-store navigation

**Market Coverage:**

- **Target Market:** Initial focus on major Dutch cities with high supermarket density
- **Store Coverage:** Albert Heijn, Jumbo, Dirk, Plus, Hoogvliet, and Lidl

**Out of Scope:**

- **Grocery Delivery Services:** No online ordering or delivery functionality
- **Meal Planning and Recipes:** No meal suggestions or recipe recommendations
- **Nutrition Tracking:** No dietary management or nutritional analysis
- **Non-Grocery Items:** Excluding pharmacy products, household goods, and general merchandise
- **International Markets:** Initial launch limited to Netherlands market

### 2.3 Objectives

**Primary Objectives:**

- **User Adoption:** Build excellent list management experience that users love and use regularly (Free tier)
- **Premium Conversion:** Enable premium users to achieve demonstrable money savings through strategic shopping
- **Market Penetration:** Establish presence in major Dutch cities starting with list users, expanding to price comparison

**Secondary Objectives:**

- **User Retention:** Achieve 30% active user retention rate among app adopters
- **Habit Formation:** Build sustainable usage patterns where users regularly leverage the app for grocery planning
- **Premium Upgrade:** Convert 25% of active free users to premium subscriptions
- **Data Intelligence:** Develop comprehensive understanding of Dutch grocery pricing patterns and consumer behavior

---

## 3. Stakeholders

### 3.1 Primary Users

- **Budget-Conscious Families:** Dutch urban families seeking to maximize grocery savings while maintaining their shopping habits. These users prioritize cost optimization and are willing to invest time in planning to achieve meaningful budget reductions.

- **Busy Professionals:** Working adults who value shopping efficiency and want to optimize their grocery spending without extensive time investment. They prefer streamlined solutions that provide maximum value with minimal effort.

- **Lower-to-Median Income Households:** Households where grocery savings have significant financial impact. These users are highly motivated to find deals and optimize their shopping strategies to stretch their grocery budgets.

**User Profile Requirements:**

- Shopping frequency preferences (weekly, bi-weekly, monthly)
- Household type and size
- Number of active shopping lists

### 3.2 Secondary Users

- **University Students:** Budget-conscious students learning to manage grocery expenses independently while studying in Dutch cities.

- **Elderly Users:** Senior citizens on fixed incomes who want to maximize their purchasing power and may have more time to invest in strategic shopping.

### 3.3 Business Stakeholders

- **Supermarket Chains:** Albert Heijn, Jumbo, Dirk, Plus, Hoogvliet, and Lidl as data sources. Initially independent data scraping approach, with potential future partnership opportunities for improved data access.

### 3.4 System Administrators

- **Data Accuracy Team:** Critical role responsible for monitoring and maintaining price data accuracy across all supermarket sources. This is the highest priority operational function given the app's dependence on reliable pricing information.

- **Customer Support:** Handle user-submitted issues, bugs, and feature requests through external integration within a ticket management app.

- **Technical Operations:** System maintenance, performance monitoring, and infrastructure management to ensure reliable service delivery.

---

## 4. User Stories & Use Cases

### 4.1 User Personas

**Persona 1: Budget-Conscious Household**

- Age: 25-65 (varies by household member)
- Tech comfort: Medium
- Goals: Save money, efficient shopping, coordinate family shopping
- Pain points: Missing deals across stores, inefficient shopping routes, coordination between family members
- Shopping behavior: Weekly shopping, price-conscious, willing to visit multiple stores for savings
- Device usage: Primarily mobile, shared family lists

**Persona 2: University Student**

- Age: 18-25
- Tech comfort: High
- Goals: Maximize budget, learn efficient shopping habits
- Pain points: Limited budget, lack of shopping experience, time constraints between studies
- Shopping behavior: Budget-focused, frequent small trips, individual lists
- Device usage: Mobile-first, personal lists only

**Persona 3: Elderly User**

- Age: 65+
- Tech comfort: Low to Medium
- Goals: Maximize purchasing power, maintain independence
- Pain points: Fixed income constraints, mobility considerations, technology learning curve
- Shopping behavior: Planned shopping trips, price-sensitive, prefer single-store efficiency
- Device usage: Tablet or mobile, may share lists with family caregivers

### 4.2 User Stories

**Epic: User Account Management**

- As a user, I want to create an account so that I can save my preferences and shopping lists
- As a user, I want to log in and out securely so that my data remains private
- As a user, I want to manage my personal information, payment details, and app settings so that I can customize my experience

**Epic: Shopping List Management**

- As a household member, I want to create shared shopping lists so that family members can collaborate on grocery planning
- As an individual user, I want to create private shopping lists so that I can manage my personal shopping needs
- As a user, I want to delete lists I no longer need so that I can keep my account organized
- As a user, I want to search for items with intelligent suggestions so that I can quickly build my shopping lists

**Epic: Shopping Optimization**

- As a user, I want to reorder my list items based on supermarket layout so that I can shop efficiently in-store
- As a user, I want to generate optimized routes (cheapest vs fastest) so that I can choose my preferred shopping strategy
- As a user, I want to integrate with external navigation apps so that I can get directions to stores
- As a user, I want to check off completed items that persist but are muted so that I can track my progress while maintaining history

**Epic: Price Comparison**

- As a grocery shopper, I want to compare prices across different stores so that I can find the best deals
- As a user, I want to see historical price trends so that I can time my purchases optimally
- As a budget-conscious shopper, I want to see total list costs across different stores so that I can make informed decisions

**Epic: Favorites and Deals**

- As a regular shopper, I want to save my favorite products so that I can quickly add them to shopping lists
- As a deal-hunter, I want to receive notifications when my favorite items go on sale so that I can take advantage of discounts
- As a budget-conscious shopper, I want to see a dashboard of current deals on my favorite items so that I can plan my shopping around promotions
- As a user, I want to organize my favorites into categories (e.g., pantry staples, weekly essentials) so that I can manage them efficiently

**Epic: Savings Tracking & Motivation**

- As a budget-conscious user, I want to see how much money I've saved on the main dashboard so that I feel motivated to continue using the app
- As a premium user, I want to track my savings over time (weekly, monthly, yearly) so that I can see the ROI of my subscription
- As a family member with shared lists, I want to see both my personal savings and our household savings so that I understand my contribution
- As a goal-oriented user, I want to set monthly savings targets and track my progress so that I stay motivated to optimize my shopping
- As a premium user, I want to see which stores and strategies save me the most money so that I can make better shopping decisions
- As a free user, I want to see "potential savings" that I'm missing so that I'm motivated to upgrade to premium

### 4.3 Use Cases

**Use Case 1: User Authentication**

- **Actor:** App User
- **Preconditions:** App is installed
- **Main Flow:**
  1. User opens app
  2. User enters login credentials
  3. System validates credentials
  4. User gains access to personal dashboard
- **Alternative Flows:** Registration flow for new users, password recovery
- **Postconditions:** User is authenticated and can access personal features

**Use Case 2: Manage Personal Settings**

- **Actor:** Authenticated User
- **Preconditions:** User is logged in
- **Main Flow:**
  1. User navigates to settings
  2. User updates personal information, payment/subscription details, or app preferences
  3. System validates and saves changes
  4. User receives confirmation
- **Alternative Flows:** Subscription management, preference updates
- **Postconditions:** User preferences are updated in system

**Use Case 3: Create and Manage Shopping Lists**

- **Actor:** Authenticated User
- **Preconditions:** User is logged in
- **Main Flow:**
  1. User creates new list (selects shared or private)
  2. User adds items using suggestive search
  3. System provides intelligent product matching and suggestions
  4. User can organize, edit, or delete lists as needed
- **Alternative Flows:** Import from previous lists, template creation
- **Postconditions:** Shopping lists are saved and accessible

**Use Case 4: Optimize Shopping Experience**

- **Actor:** User with populated shopping list
- **Preconditions:** List contains items, user location is available
- **Main Flow:**
  1. User selects optimization preference (cheapest vs fastest)
  2. System generates optimal route and store selection
  3. User chooses to reorder list by supermarket layout
  4. User initiates navigation to selected store(s)
  5. External navigation app opens with directions
- **Alternative Flows:** Manual store selection, route modification
- **Postconditions:** User has optimized shopping plan and navigation guidance

**Use Case 5: Manage Favorite Products and Deal Notifications**

- **Actor:** Authenticated User
- **Preconditions:** User is logged in
- **Main Flow:**
  1. User browses products or searches for specific items
  2. User adds products to favorites list with optional price threshold
  3. System monitors prices for favorited items across all stores
  4. When item goes on sale system sends notification
  5. User views deal notification and can quickly add item to shopping list
- **Alternative Flows:**
  - User organizes favorites into custom categories (pantry, weekly essentials, etc.)
  - User shares favorites with family members for collaborative deal hunting
  - User adjusts notification preferences (frequency, discount percentage)
- **Postconditions:** User maintains curated list of favorite products with automated deal tracking

**Use Case 6: Track Shopping Progress**

- **Actor:** User shopping with active list
- **Preconditions:** User has shopping list, is in-store or shopping
- **Main Flow:**
  1. User checks off items as they shop
  2. Completed items become muted but remain on list
  3. User can view progress and remaining items
  4. User can permanently remove completed items when desired
- **Alternative Flows:** Undo check-off, bulk completion actions
- **Postconditions:** Shopping progress is tracked, list history is maintained

**Use Case 7: Track and View Savings**

- **Actor:** Premium User
- **Preconditions:** User has premium subscription, has completed shopping trips with price optimization
- **Main Flow:**
  1. User opens app dashboard
  2. System displays prominent savings counter with current month savings
  3. User can tap counter to view detailed savings breakdown
  4. System shows savings by time period, store, and product category
  5. User can view personal vs household savings for shared lists
  6. User can see progress toward monthly savings goals
- **Alternative Flows:**
  - Free user sees "potential savings" preview to encourage premium upgrade
  - User sets or modifies monthly savings goals
  - User shares savings achievements with family members
- **Postconditions:** User feels motivated by savings achievements and continues using optimization features

---

## 5. Functional Requirements

### 5.1 Core Features

**FR-001: User Authentication & Account Management**

- The system SHALL allow users to register with email and password
- The system SHALL provide secure login and logout functionality
- The system SHALL include password recovery mechanism
- The system SHALL allow users to update personal information, app settings, and subscription details
- The system SHALL maintain user session security and data privacy

**FR-002: Product Search & AI Matching**

- The system SHALL allow users to search for grocery products by name using intelligent text search
- The system SHALL implement AI-powered product matching that maps generic terms (e.g., "peanut butter") to specific brands and variations
- The system SHALL provide search suggestions and autocomplete functionality
- The system SHALL display product information including name, brand and size

**FR-003: Shopping List Management**

- The system SHALL allow users to create multiple shopping lists
- The system SHALL support both private (personal) and shared (family/household) list types
- The system SHALL provide real-time synchronization for shared lists across multiple users
- The system SHALL allow users to add items via intelligent search with product suggestions
- The system SHALL enable list editing, including item modification and deletion
- The system SHALL allow complete list deletion when no longer needed
- The system SHALL support list templates and recurring shopping patterns

**FR-004: Price Comparison & Analysis**

- The system SHALL aggregate real-time pricing data from target Dutch supermarkets (Albert Heijn, Jumbo, Dirk, Plus, Hoogvliet, Lidl)
- The system SHALL display price comparisons across multiple stores for individual items
- The system SHALL show total shopping list cost comparisons across different stores
- The system SHALL maintain historical price data and display price trends
- The system SHALL calculate and display potential savings for different shopping strategies
- The system SHALL identify current promotions and discounts affecting list items

**FR-005: Route Optimization**

- The system SHALL generate optimized shopping routes based on user preference (cheapest vs fastest)
- The system SHALL consider store locations, travel time, and user's current location
- The system SHALL provide route recommendations for single-store or multi-store shopping strategies
- The system SHALL integrate with external navigation applications (Google Maps, Apple Maps, Waze)
- The system SHALL allow manual store selection and route modification
- The system SHALL calculate estimated total shopping time including travel

**FR-006: In-Store Shopping Assistance**

- The system SHALL reorder shopping list items based on typical supermarket layouts for efficient in-store navigation
- The system SHALL allow users to check off items as they shop
- The system SHALL mute completed items while preserving them in list history
- The system SHALL provide option to permanently remove completed items
- The system SHALL support bulk completion and undo functionality

### 5.2 Additional Features

**FR-007: Data Synchronization & Offline Support**

- The system SHALL provide offline access to previously loaded shopping lists
- The system SHALL synchronize data when internet connection is restored
- The system SHALL maintain data consistency across multiple devices per user account

**FR-008: User Preferences & Customization**

- The system SHALL allow users to set default optimization preferences (price vs time priority)
- The system SHALL remember frequently purchased items and shopping patterns
- The system SHALL provide customizable notification settings
- The system SHALL support multiple household members with different permission levels for shared lists

**FR-009: Freemium Model Support**

- The system SHALL provide complete list management functionality for free users
- The system SHALL restrict price comparison, route optimization, and advanced features to premium users
- The system SHALL allow seamless upgrade/downgrade between subscription tiers
- The system SHALL maintain core list functionality even if user downgrades from premium
- Free tier SHALL support basic lists, sharing, and up to 10 favorite items
- Premium tier SHALL support unlimited favorites, price alerts, route optimization, and deal notifications

**FR-010: Favorites & Discount Notifications**

- The system SHALL allow users to save frequently purchased items as favorites for quick access
- The system SHALL enable users to add products to favorites directly from search results or shopping lists
- The system SHALL allow users to organize favorites into custom categories (e.g., pantry staples, weekly essentials, household items)
- The system SHALL monitor prices for all favorited items across target supermarket chains
- The system SHALL send push notifications when favorite items go on sale or drop below user-defined price thresholds
- The system SHALL allow users to set custom discount percentage thresholds (e.g., notify when 15% off or more)
- The system SHALL provide a dedicated "Deals Dashboard" showing current promotions on favorite items
- The system SHALL allow users to quickly add favorited items to any shopping list with one tap
- The system SHALL support sharing favorite items with household members for collaborative deal hunting
- The system SHALL provide notification preferences (immediate, daily digest, weekly summary)
- The system SHALL track deal history for favorite items to help users understand seasonal pricing patterns
- The system SHALL allow bulk management of favorite items (add multiple, remove, categorize)

**FR-011: Savings Counter & Analytics (Premium)**

- The system SHALL display a prominent savings counter on the main dashboard showing money saved through price optimization
- The system SHALL calculate savings by comparing user's chosen stores/route vs highest-price alternative for the same shopping list
- The system SHALL track savings over multiple time periods (this week, this month, this year, all-time)
- The system SHALL provide separate counters for personal savings and household savings for shared lists
- The system SHALL assign full savings value to each individual user for shared lists to maximize motivation
- The system SHALL display list-specific savings on individual shopping list views
- The system SHALL show savings breakdown by store and by product category
- The system SHALL provide savings history and trends with visual charts
- The system SHALL allow users to set monthly savings goals and track progress
- The system SHALL display "potential additional savings" for users who haven't fully optimized their routes
- The system SHALL persist savings data even if user downgrades from premium (read-only historical view)
- The system SHALL use savings metrics as primary conversion tool for free-to-premium upgrades

---

## 6. Non-Functional Requirements

### 6.1 Performance

- **Response Time:**
  - General user interactions must respond within 3 seconds
  - Route optimization (cheapest vs fastest) must complete within 5 seconds
  - Real-time list synchronization between shared users must complete within 3 seconds
- **Scalability:**
  - System must initially support 25 concurrent users
  - System must be architecturally designed to scale to 300,000+ users in future phases
  - Database and infrastructure must support horizontal scaling capabilities
- **Availability:** 99% system uptime
- **Data Processing:**
  - Price comparison calculations must complete within 5 seconds for typical shopping lists (20-50 items)
  - Product search results must display within 2 seconds

### 6.2 Usability

- **Accessibility:** Must comply with WCAG 2.1 AA standards including:
  - Keyboard navigation support
  - Screen reader compatibility
  - Color contrast ratios meeting AA standards (4.5:1 for normal text, 3:1 for large text)
  - Alternative text for images and icons
  - Focus indicators for interactive elements
  - Resizable text up to 200% without loss of functionality
- **Platform Priority:**
  - **Phase 1:** Web application (responsive design for mobile and desktop)
  - **Phase 2:** Native iOS and Android applications
- **User Experience:**
  - Interface must be intuitive for users with low to medium tech comfort levels (elderly users)
  - Simple navigation with clear visual hierarchy
  - Minimal cognitive load for core shopping list functions

### 6.3 Compatibility

- **Web Browsers:**
  - Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
  - Mobile browsers: Chrome Mobile, Safari Mobile, Samsung Internet
- **Future Native Apps:**
  - iOS 14+ (iPhone and iPad)
  - Android 8+ (API level 26+)
- **Devices:** Smartphones, desktop computers
- **Offline Capability:**
  - Core shopping list functionality available without internet connection
  - Automatic synchronization when connection is restored
  - Cached product data for frequently used items

### 6.4 Capacity & Scalability

- **Initial Phase (Year 1):**
  - 25-100 registered users
  - Average 1 shopping list per user
  - Predominantly shared lists (hosted by single account, accessed by multiple family members)
- **Future Scalability Target:**
  - Architecture must support scaling to 300,000+ users
  - Database partitioning and load balancing capabilities
  - Microservices architecture to support independent scaling of components

### 6.5 Data Management

- **List Synchronization:**
  - Real-time updates for shared lists across all connected devices
  - Conflict resolution for simultaneous edits
  - Version history for shared list changes
- **Storage:**
  - User data must be persistently stored with regular backups
  - Shopping list history retained for user convenience and habit analysis

---

## 7. System Architecture

### 7.1 High-Level Architecture

Baskit follows a microservices architecture designed for scalability and maintainability. The system is containerized using Docker and orchestrated with Docker Compose for local deployment on NAS infrastructure, with future migration path to Kubernetes for cloud scaling.

**Architecture Components:**

- **Frontend Layer:** Flutter web application serving responsive UI
- **API Gateway:** Nginx reverse proxy with load balancing and SSL termination
- **Microservices Layer:** Independent services handling specific business domains
- **Data Layer:** PostgreSQL for relational data, Redis for caching and real-time messaging
- **External Integrations:** Puppeteer-based scrapers and third-party APIs

**Communication Patterns:**

- **Synchronous:** REST APIs for request-response operations
- **Asynchronous:** WebSockets with Redis pub/sub for real-time updates
- **Inter-service:** HTTP/JSON for service-to-service communication

### 7.2 Technology Stack

**Frontend:**

- **Framework:** Flutter Web (with future iOS/Android app capability)
- **State Management:** Bloc/Cubit pattern for reactive state management
- **HTTP Client:** Dio for API communication
- **WebSocket:** Socket.IO client for real-time updates
- **Offline Storage:** SQLite/Hive for local caching and offline functionality

**Backend Microservices:**

- **Runtime:** Node.js with TypeScript for consistency and rapid development
- **Framework:** Express.js with Helmet for security
- **API Documentation:** OpenAPI/Swagger for service contracts
- **Validation:** Joi for request validation
- **Logging:** Winston with structured logging for observability

**Databases:**

- **Primary Database:** PostgreSQL 15+ with JSONB support
- **Caching Layer:** Redis 7+ for session storage, caching, and pub/sub messaging
- **Future Extension:** Vector database (Pinecone/Weaviate) for AI-powered product matching

**Infrastructure:**

- **Containerization:** Docker with multi-stage builds for optimization
- **Orchestration:** Docker Compose for local NAS deployment
- **Reverse Proxy:** Nginx for load balancing and SSL termination
- **Monitoring:** Prometheus + Grafana for metrics and alerting

**Data Scraping:**

- **Framework:** Puppeteer with Node.js for headless browser automation
- **Scheduling:** Node-cron for automated scraping jobs
- **Rate Limiting:** Custom throttling to respect supermarket websites
- **Data Processing:** Cheerio for HTML parsing and data extraction

### 7.3 Microservices Architecture

**Core Services:**

**1. User Service**

- User authentication and authorization (JWT tokens)
- Profile management and preferences
- Account settings and subscription management
- Database: Users, UserPreferences tables

**2. Product Service**

- Product catalog management and search
- AI-powered product matching using vector similarity
- Category management and product attributes
- Database: Products, Categories, ProductVariations tables

**3. List Service**

- Shopping list CRUD operations
- Real-time synchronization for shared lists
- List templates and recurring patterns
- Database: Lists, ListItems, ListSharing tables

**4. Price Service**

- Price data aggregation and storage
- Historical price tracking and trends
- Promotion and discount detection
- Database: Prices, PriceHistory, Promotions tables

**5. Store Service**

- Store information and locations
- Store layout data for in-store navigation
- Operating hours and contact information
- Database: Stores, StoreLayouts tables

**6. Route Service**

- Route optimization algorithms (cheapest vs fastest)
- Integration with mapping services
- Travel time calculations
- External APIs: Google Maps, HERE Maps

**7. Notification Service**

- Push notifications for promotions and updates
- Email notifications for shared list changes
- Future: Favorite item discount alerts
- Message Queue: Redis pub/sub

**8. Scraper Service**

- Automated price scraping from supermarket websites
- Data validation and cleaning
- Scheduling and rate limiting
- Error handling and retry mechanisms

### 7.4 Real-Time Synchronization Strategy

**WebSocket + Redis Pub/Sub Architecture:**

**Client-Side (Flutter):**

- WebSocket connection to API Gateway
- Automatic reconnection with exponential backoff
- Local state synchronization with server updates
- Conflict resolution for simultaneous edits

**Server-Side:**

- WebSocket handler service for client connections
- Redis pub/sub for broadcasting updates across service instances
- Message queuing for guaranteed delivery
- Event sourcing for audit trail and conflict resolution

**Synchronization Flow:**

1. User makes change to shared list in Flutter app
2. HTTP API call to List Service updates database
3. List Service publishes event to Redis channel
4. WebSocket handler subscribes to Redis events
5. Handler broadcasts update to all connected clients for that list
6. Other users receive real-time update in their Flutter apps

**Conflict Resolution:**

- Last-write-wins with timestamp comparison
- Operational transformation for text edits
- User notification for major conflicts
- Version history for rollback capability

### 7.5 External Dependencies

**Required Integrations:**

**Navigation Services:**

- Google Maps API for route optimization and directions
- HERE Maps API as backup provider
- Integration via Route Service with fallback mechanisms

**Supermarket Data Sources:**

- Albert Heijn: Web scraping via Puppeteer
- Dirk: API integration if available, otherwise scraping
- Plus: Web scraping with custom parsers
- Hoogvliet: Web scraping via Puppeteer
- Lidl: Web scraping with anti-bot detection handling

**Future Payment Processing:**

- Stripe or Mollie for subscription management
- Integration via dedicated Payment Service
- PCI DSS compliance considerations

**AI/ML Services (Future):**

- OpenAI API for natural language product matching
- Vector database (Pinecone/Weaviate) for semantic search
- Custom ML models for price prediction

### 7.6 Scalability Considerations

**Current NAS Deployment:**

- Docker Compose with service scaling capabilities
- Nginx load balancing across service instances
- PostgreSQL connection pooling
- Redis clustering for high availability

**Future Cloud Migration Path:**

- Kubernetes manifests for container orchestration
- Horizontal pod autoscaling based on CPU/memory metrics
- Database sharding strategies for PostgreSQL
- CDN integration for static assets
- Message queue scaling with Redis Cluster or RabbitMQ

**Performance Optimization:**

- Database indexing strategy for fast queries
- Redis caching for frequently accessed data
- API response compression and pagination
- Image optimization and lazy loading in Flutter
- Background job processing for heavy operations

---

## 8. Risk Analysis

### 8.1 Technical Risks

**8.1.1 High-Impact Technical Risks**

**Risk: API rate limiting and blocking from grocery stores**

- **Impact:** High - Core functionality severely limited
- **Probability:** Medium - Inevitable with web scraping at scale
- **Description:** Supermarket websites may implement rate limiting, IP blocking, or anti-bot measures that prevent data collection
- **Mitigation Strategies:**
  - Implement distributed scraping with IP rotation and proxy pools
  - Develop respectful scraping patterns with randomized delays
  - Build comprehensive caching system to reduce scraping frequency
  - Negotiate formal API partnerships with willing chains
  - Develop fallback data sources including user-contributed pricing
- **Contingency Plan:** Switch to user-crowdsourced pricing model if scraping becomes unsustainable
- **Monitoring:** Real-time scraping success rate tracking with automated alerts

**Risk: Data accuracy and consistency issues**

- **Impact:** High - Erodes user trust and app value
- **Probability:** Medium - Inherent challenge with automated data collection
- **Description:** Price discrepancies, outdated information, or incorrect product matching could mislead users
- **Mitigation Strategies:**
  - Implement multiple data validation layers and anomaly detection
  - Cross-reference prices across different data sources
  - Build user reporting system for price corrections
  - Implement confidence scoring for price data
  - Regular manual spot-checking of critical product prices
- **Quality Metrics:** Track price accuracy through user feedback and manual verification
- **Recovery Plan:** Automated price correction workflows and transparent accuracy indicators

**Risk: Scalability limitations of NAS infrastructure**

- **Impact:** High - Service degradation or outages during growth
- **Probability:** Low - Manageable with proper planning
- **Description:** Local NAS deployment may not handle unexpected user growth or traffic spikes
- **Mitigation Strategies:**
  - Design cloud-ready architecture from day one
  - Implement horizontal scaling capabilities within NAS constraints
  - Monitor resource utilization with automated scaling alerts
  - Prepare cloud migration plan for rapid deployment
  - Load testing to identify bottlenecks before they impact users
- **Trigger Points:** Migrate to cloud when exceeding 70% NAS capacity or 1000+ concurrent users

**8.1.2 Medium-Impact Technical Risks**

**Risk: Third-party service dependencies**

- **Impact:** Medium - Feature degradation but core functionality maintained
- **Probability:** Low - Well-established service providers
- **Description:** Google Maps, email services, or payment processors could experience outages
- **Mitigation:** Fallback services configured for all critical dependencies
- **Example:** OpenStreetMap fallback for Google Maps, backup email service provider

**Risk: Database performance degradation**

- **Impact:** Medium - Slow response times affecting user experience
- **Probability:** Medium - Predictable with growth patterns
- **Description:** PostgreSQL performance may degrade with large datasets and concurrent users
- **Mitigation:** Database optimization, query tuning, read replicas, and caching layers
- **Monitoring:** Query performance tracking with automated optimization recommendations

**Risk: Security vulnerabilities in dependencies**

- **Impact:** Medium to High - Potential data breaches or service compromise
- **Probability:** Medium - Common in software ecosystems
- **Description:** Node.js packages, Flutter dependencies, or infrastructure components may have security flaws
- **Mitigation:** Automated dependency scanning, regular updates, and security monitoring
- **Response Plan:** 24-hour security patch deployment process for critical vulnerabilities

### 8.2 Business Risks

**8.2.1 Market and Competition Risks**

**Risk: Market dominance by single supermarket chain**

- **Impact:** High - Core value proposition becomes obsolete
- **Probability:** Medium - Depends on actual price competitiveness in Dutch market
- **Description:** If analysis reveals that one supermarket (e.g., Lidl) consistently offers the lowest prices across most grocery lists, users will quickly recognize this pattern and stop using the app for price optimization, instead defaulting to that single store.
- **Mitigation Strategies:**
  - Implement freemium model where basic list functionality remains free even if price optimization becomes less valuable
  - Focus on other value propositions like convenience, store layout optimization, and habit tracking
  - Expand to include non-price factors like product quality, store experience, and location convenience
  - Monitor market competitiveness during beta testing and adjust strategy accordingly
- **Early Detection:** Weekly analysis of price spread across stores during beta testing
- **Pivot Strategy:** Shift focus to convenience and list management features if price optimization becomes less valuable

**Risk: Insufficient price variation across stores**

- **Impact:** High - Reduces user engagement and retention
- **Probability:** Medium - Unknown until data collection begins
- **Description:** If price differences between stores are minimal (less than 5-10% for typical shopping lists), users may not perceive sufficient value to justify using the app regularly.
- **Mitigation Strategies:**
  - Focus on promotional periods and seasonal variations where price differences are more significant
  - Emphasize cumulative savings over time rather than per-trip savings
  - Integrate loyalty programs and store-specific discounts to increase actual price variations
  - Highlight non-price benefits like time savings and convenience
- **Success Metrics:** Minimum 15% average savings potential required for viable value proposition
- **Alternative Strategy:** Focus on promotional deal aggregation and time-limited offers

**Risk: Legal challenges from supermarket chains**

- **Impact:** Medium - Could limit data access or require operational changes
- **Probability:** Low - Price information is generally public
- **Description:** Supermarket chains might object to systematic data scraping or price comparison services, potentially leading to legal action or technical countermeasures.
- **Mitigation Strategies:**
  - Ensure compliance with terms of service and applicable laws
  - Consider formal partnership discussions with willing chains
  - Develop alternative data sources including user-contributed pricing
  - Engage legal counsel specializing in data scraping and competition law
  - Maintain ethical scraping practices and respect robots.txt
- **Legal Preparation:** Retain legal counsel familiar with EU competition law and data scraping regulations
- **Partnership Approach:** Proactive outreach to chains highlighting mutual benefits

**8.2.2 User Adoption and Retention Risks**

**Risk: User behavior doesn't align with optimization suggestions**

- **Impact:** Medium - Reduces perceived value and user satisfaction
- **Probability:** Medium - Users have established shopping habits and preferences
- **Description:** Users may prefer convenience, brand loyalty, or other factors over pure price optimization, leading to low adoption of recommendations.
- **Mitigation Strategies:**
  - Provide multiple optimization options (price, time, convenience, mixed)
  - Allow user preference weighting for different factors
  - Include qualitative factors in recommendations (store experience, product quality)
  - Implement gradual behavior change techniques with small, achievable suggestions
  - Gamification elements to encourage engagement with optimization features
- **User Research:** Regular surveys and behavioral analysis to understand user priorities
- **Adaptive Algorithm:** Machine learning to personalize recommendations based on user behavior patterns

**Risk: Low user engagement with collaborative features**

- **Impact:** Medium - Reduced viral growth and user retention
- **Probability:** Medium - Family sharing features require coordination
- **Description:** Shared shopping lists may not be adopted if family members don't actively participate or find the collaboration cumbersome.
- **Mitigation Strategies:**
  - Simplify sharing process with one-click invitations
  - Implement smart notifications that don't overwhelm users
  - Provide clear value demonstration for collaborative features
  - Design for asymmetric usage patterns (one active organizer, multiple passive participants)
- **Success Metrics:** Target 40% of lists to be shared lists with at least 2 active participants
- **User Education:** In-app tutorials and success stories demonstrating collaboration benefits

**Risk: Elderly users unable to adopt mobile technology**

- **Impact:** Medium - Limits market penetration in key demographic
- **Probability:** Medium - Digital divide affects elderly population
- **Description:** Despite accessibility features, some elderly users may struggle with smartphone/tablet interfaces.
- **Mitigation Strategies:**
  - Develop simplified interface mode with larger buttons and reduced complexity
  - Provide comprehensive user support and tutorials
  - Consider desktop web interface optimization
  - Partner with community organizations for digital literacy support
  - Implement voice interface capabilities for hands-free interaction
- **Support Strategy:** Dedicated customer support for elderly users with extended response times
- **Community Outreach:** Partnerships with senior centers and community organizations

### 8.3 Regulatory and Compliance Risks

**8.3.1 Data Protection and Privacy Risks**

**Risk: GDPR compliance violations**

- **Impact:** High - Significant fines and legal consequences
- **Probability:** Low - Comprehensive compliance framework in place
- **Description:** Inadvertent violations of GDPR requirements could result in regulatory action from Dutch Data Protection Authority
- **Mitigation Strategies:**
  - Regular privacy impact assessments for new features
  - Legal review of all data processing activities
  - Automated compliance monitoring and auditing
  - Staff training on privacy requirements
  - External privacy compliance audits
- **Compliance Monitoring:** Quarterly reviews with external privacy counsel
- **Response Plan:** Incident response procedure for potential privacy breaches

**Risk: Changes in EU data protection regulations**

- **Impact:** Medium - May require significant compliance updates
- **Probability:** Low - Major regulatory changes are infrequent
- **Description:** New regulations or interpretations could require changes to data handling practices
- **Mitigation:** Stay informed through legal counsel and industry associations
- **Adaptation Strategy:** Flexible architecture allowing for rapid compliance updates

**8.3.2 Competition and Market Regulation Risks**

**Risk: EU competition law challenges**

- **Impact:** Medium - May restrict certain business practices
- **Probability:** Low - Operating within established market norms
- **Description:** Price comparison services could face scrutiny under competition regulations
- **Mitigation:** Ensure all practices comply with EU competition law and promote market competition
- **Legal Guidance:** Regular consultation with competition law experts

---

## Document Approval

| Role           | Name | Signature | Date |
| -------------- | ---- | --------- | ---- |
| Product Owner  |      |           |      |
| Technical Lead |      |           |      |
| Stakeholder    |      |           |      |

---

_This document is a living document and will be updated as the project evolves._
