# Hospitality and Tourism Management System

Java 21+, JavaFX 21, FXML, Maven, MySQL/JDBC and JasperReports 7 desktop application.

## Start

On this Windows computer, double-click **Run-HTMS.cmd**. The launcher finds an installed JDK, builds/tests the application and starts the login screen. MySQL must already be running with the existing htms1 database. Existing account credentials remain unchanged.

Eclipse can continue running `com.htms.Main`; the project architecture and resource paths are preserved. Maven resolves the new Jasper PDF dependency from pom.xml.

## Database configuration

Current local settings are preserved in `database.local.properties` at the project root. That file is ignored by Git and is not packaged in the application JAR. Do not share it.

For another installation, copy `database.example.properties` to `database.local.properties` and configure that installation. Environment variables `HTMS_DB_URL`, `HTMS_DB_USER` and `HTMS_DB_PASSWORD` override file values. `-Dhtms.config=<path>` selects another configuration file. Use a dedicated MySQL application user for production.

## Reports

- Billing: select an invoice, then **Invoice Preview / Print** or **Save Invoice PDF**.
- Reports: select Payments, Invoices or Reservations and a date range, then **Load Report**. Jasper preview includes printer controls; PDF and CSV are available separately.
- JasperReports 7 editable source templates: `src/main/resources/reports/invoice.jrxml` and `financial-report.jrxml`.
- Payment reports filter payment timestamps; invoice reports filter invoice dates; reservation reports filter scheduled arrival dates.

## Validation

`./build.ps1` builds and runs tests that do not write to MySQL. `./build.ps1 -IntegrationTests` additionally runs tests that create and verify connection-local MySQL TEMPORARY tables, then exercise real DAO transaction code against those isolated fixtures. Live records are not modified. Temporary table creation permission is required.

`src/test/java/com/htms/SecuredUiCheck.java` loads all FXML screens, checks role visibility and takes off-screen screenshots. It writes only temporary user/role/audit fixtures and reads existing hotel data. Test reports and screenshots live in the ignored target folder.

See DEVELOPMENT_STATUS.md for implemented functionality, verification limits and the remaining commercial product scope.

## Roles and audit log

Access is enforced for ADMIN, MANAGER, RECEPTIONIST and HOUSEKEEPING. ADMIN users can open Administration → System Activity Log. See ACCESS_AND_AUDIT.md for the complete policy and logging behavior. The required audit_logs table has been added to the local database.

