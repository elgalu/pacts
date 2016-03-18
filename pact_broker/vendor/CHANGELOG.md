Do this to generate your change history

    $ git log --pretty=format:'  * %h - %s (%an, %ad)' vX.Y.Z..HEAD

#### 1.9.1.pre.jruby (2016-03-18)
* 86ab2f3 - Add JRuby support. Drop mysql&sqlite support and force psql. Moved from Redcarpet to Kramdown.

#### 1.9.1 (2016-02-26)
* e6e6d49 - Release version 1.9.1 (Sergei Matheson, Fri Feb 26 09:26:52 2016 +1100)
* 5ea7607 - Merge pull request #44 from sigerber/master (Beth Skurrie, Thu Feb 25 14:39:17 2016 +1100)
* ade2599 - Fix performance of groupify (Horia Musat and Simon Gerber, Wed Feb 24 14:50:39 2016 +1100)
* 38869ad - Return a 409 when there is a potential duplicate pacticipant name when publishing a pact. (Beth, Thu Nov 5 17:43:32 2015 +1100)
* 2991441 - Merge pull request #42 from bethesque/issue-41 (Beth Skurrie, Fri Oct 23 15:52:39 2015 +1100)
* 933981c - Now supports HTTPS webhooks (Warner Godfrey, Fri Oct 23 14:48:28 2015 +1100)
* 2123ff1 - Merge pull request #40 from elgalu/travis-badge (Beth Skurrie, Thu Oct 15 06:40:09 2015 +1100)
* 88cea3f - Add TravisCI badge in README.md (Leo Gallucci, Wed Oct 14 17:02:52 2015 +0200)
* b54c5c6 - Merge pull request #38 from gitter-badger/gitter-badge (Beth Skurrie, Tue Sep 29 15:37:27 2015 +1000)
* 42e9bc2 - Add Gitter badge (The Gitter Badger, Tue Sep 29 04:51:17 2015 +0000)
* 711ac85 - Merge pull request #37 from elgalu/ruby-2.1.3 (Beth Skurrie, Fri Sep 18 06:42:47 2015 +1000)
* 40ddb97 - Add ruby 2.1.3 and set as default (Leo Gallucci, Thu Sep 17 16:19:09 2015 +0200)
* a1fa248 - Updated example with postgres details (Beth, Thu Sep 17 09:25:09 2015 +1000)
* 383d137 - Create LICENSE.txt (Beth Skurrie, Mon Aug 24 06:29:50 2015 +1000)

#### 1.9.0 (2015-08-19)

* eda171e - Allow pact broker API to be run using Rack map at an arbitrary path. e.g. "/foo/pacts". Note, this does not work for the UI. (Beth, Wed Aug 19 08:44:21 2015 +1000)

#### 1.9.0.rc1 (2015-07-19)

* c855a2c - Support case insensitive resource names (Beth Skurrie, Sun Jul 19 17:28:55 2015 +1000)
* 7ea3e61 - Update pact_broker.gemspec (Beth Skurrie, Tue Jul 14 09:02:30 2015 +1000)
* f299cfd - Added logging for publishing and deleting pacts (Beth Skurrie, Wed Jul 8 16:00:58 2015 +1000)
* 67f0edb - Log error when contract cannot be parsed to a Pact (Beth Skurrie, Wed Jul 8 15:54:29 2015 +1000)
* 57caf63 - Double ensure that tables are created with UTF-8 encoding https://github.com/bethesque/pact_broker/issues/24 (Beth Skurrie, Fri Jul 3 15:46:46 2015 +1000)

#### 1.8.1 (2015-06-30)

* d0d466d - Avoid making a query for tags for each pact shown on the Pacts page (Beth Skurrie, Tue Jun 30 06:42:09 2015 +1000)

#### 1.8.0 (2015-05-28)

* 6c40e9c - Added ability to specify a tag when retrieving pacts for a given provider (Beth Skurrie, Thu May 28 09:03:46 2015 +1000)
* dda9f1d - Added endpoint to retrieve latest pacts by provider (Beth Skurrie, Sun May 10 21:28:33 2015 +1000)
* 21e676a - Pact broker example for heroku with basic auth (BrunoChauvet, Sat Apr 25 13:04:54 2015 +1000)

#### 1.7.0 (2015-03-20)

* a26402c - Allow configuration of version parsing. (Beth Skurrie, Tue Apr 14 09:39:05 2015 +1000)

#### 1.6.0 (2015-03-20)

* e20e657 - Added support for JSON contracts that are not in the Pact format (e.g. top level is an array) (Beth Skurrie, Fri Mar 20 19:12:46 2015 +1100)

#### 1.5.0 (2015-02-20)

* b848ce3 - Added healthcheck endpoint for database dependency. /diagnostic/status/dependencies (Beth, Fri Feb 20 09:41:16 2015 +1100)
* 56ea4a6 - Added heartbeat endpoint for monitoring. /diagnostic/status/heartbeat (Beth, Fri Feb 20 08:49:51 2015 +1100)
* dbdb4fb - Upgraded webmachine gem to 1.3.1 (Beth, Wed Feb 11 21:49:55 2015 +1100)
* 111f088 - Added validation to ensure that the encoding for the database connection is set to UTF8. This is required to ensure the pact_version_content_sha foreign key works. (Beth, Wed Feb 11 20:03:34 2015 +1100)

#### 1.4.0 (2015-01-20)

* d740fb0 - Removed pact-versions rel from pact resource. Pact versions resource is not implemented yet. (Beth, Tue Jan 20 09:20:52 2015 +1100)
* bd6e63e - Handle case where there is no previous distinct version when displaying diff (Beth, Tue Jan 20 09:17:21 2015 +1100)
* d032ce1 - Changed pact icon on Pacts page to look more like a pact. (Beth, Wed Dec 24 09:58:35 2014 +1100)
* dbf67aa - Added endpoint for previous distinct pact version. (Beth, Mon Dec 22 14:08:07 2014 +1100)
* bde72f9 - Added migration to change pacts table to UTF8 (Beth, Mon Dec 22 11:45:09 2014 +1100)
* 8f587b7 - Modified pact HAL rels. (Beth, Mon Dec 22 11:41:10 2014 +1100)
* b813c0d - Renamed Relationships to Pacts. It was confusing. (Beth, Mon Dec 22 10:25:27 2014 +1100)
* 00d81aa - Changed diff resource to text/plain, added dates (Beth, Sun Dec 14 17:05:18 2014 +1100)
* 8f05772 - Set timezone to utc for test db connection (Beth, Sun Dec 14 17:04:16 2014 +1100)
* 407fa74 - Added link from HAL browser to home (Beth, Sat Dec 13 19:54:53 2014 +1100)
* a62faa9 - Adding missing docs (Beth, Sat Dec 13 19:51:36 2014 +1100)
* ec04e77 - Added HAL link to diff with previous distinct version (Beth, Fri Dec 12 08:31:12 2014 +1100)
* fe5f1d6 - Added endpoint to see the diff between a pact and the previous distinct version. (Beth, Thu Dec 11 17:35:22 2014 +1100)
* f802641 - Added version endpoint. (Beth, Wed Dec 10 13:06:13 2014 +1100)
* 715f49d - Force documentation window in HAL browser to be longer. This used to display correctly, but has somehow become quite short. Don't know what changed. (Beth, Tue Dec 9 18:47:53 2014 +1100)
* 25e612b - Removed curie from self links (Beth, Wed Dec 3 21:14:23 2014 +1100)
* 5cc922e - Added script to publish test pact. (Beth, Wed Dec 3 20:26:31 2014 +1100)
* f468b2c - Changed Padrino to log to stdout. :null creates a StringIO, don't want to hog memory. (Beth, Wed Dec 3 20:25:05 2014 +1100)

#### 1.3.2.rc1 (2014-12-03)

* a2413f4 - Stop Padrino trying to create a log file in the gem directory https://github.com/bethesque/pact_broker/issues/13 (Beth, Wed Dec 3 13:16:06 2014 +1100)
* abf9459 - Added DELETE endpoint for pact resource (Beth, Wed Nov 19 17:45:34 2014 +1100)
* 1d01937 - Set default encoding to utf-8 in example app. This is required for the sha foreign key to work between the pact table and the pact_version_content table. (Beth, Tue Nov 18 22:35:51 2014 +1100)
* 9e3401e - Save all the space! Reuse the same pact_version_content when one with the same sha1 already exists in the database. (Beth, Tue Nov 18 20:27:59 2014 +1100)
* 84ab8ad - Creating example pact_broker_database.sqlite3 with the Zoo App/Animal Service pact (Beth, Tue Nov 18 17:30:25 2014 +1100)
* d767b0d - Fixed query for all pacts when pact has more than one tag (Beth, Mon Nov 17 20:44:01 2014 +1100)
* 21563c6 - Changed date to use day name and month name instead of numbers (Beth, Wed Nov 12 16:19:19 2014 +1100)
* 7766b77 - Added count to relationships page. (Beth, Mon Nov 3 11:06:05 2014 +1100)

#### 1.3.1 (2014-10-23)

* e61b40e - Added Travis configuration. (Beth, Fri Oct 17 16:32:26 2014 +1100)
* b320fe4 - Fixed pact publish validation for ruby 1.9.3 (Beth, Fri Oct 17 16:31:41 2014 +1100)
* b9b4d2b - Added validation to ensure that the participant names in the path match the participant names in the pact. (Beth, Thu Oct 16 20:21:10 2014 +1100)

#### 1.3.0 (2014-10-14)

* ed08811 - Converted raw SQL create view statements to Sequel so they will run on Postgres (Beth, Sat Oct 11 22:07:37 2014 +1100)
* 457edf4 - Added syntax highlighting to JSON in autogenerated HTML docs. (Beth, Wed Sep 24 22:12:14 2014 +1000)

#### 1.2.0 (2014-09-22)

* 0ccde50 - Made webhook creation code more Webmachiney. (Beth, Tue Sep 16 10:07:56 2014 +1000)
* 4c628e5 - Using localtime to display dates. (Beth, Fri Aug 29 13:32:20 2014 +1000)
* 7d99c51 - Fixed HAL Browser link - page title was stopping it being clickable (Beth, Fri Sep 5 16:41:03 2014 +1000)
* 8ba3be0 - Updating spec task for latest rspec (Beth, Fri Sep 5 16:40:10 2014 +1000)
* fcc25eb - Updated pact gem (Beth, Tue Aug 26 18:45:31 2014 +1000)
* 5d0d3dc - Added pact versions link to the pact response (Beth, Tue Aug 26 07:54:26 2014 +1000)
* 16971ff - Added method to find distinct pacts between a consumer and provider (Beth, Tue Aug 26 07:41:54 2014 +1000)
* 4798c09 - Added pact versions endpoint. (Beth, Mon Aug 25 22:23:48 2014 +1000)
* e1f8c97 - Changed 'Date published' to display pact.updated_at date instead of created_at date (Beth, Mon Aug 25 07:37:58 20
* 39eac31 - Fixed pact-webhooks rel title (Beth, Sun Aug 24 17:54:05 2014 +1000)
* f6fc9f7 - Added latest-pact rel to pact representation (Beth, Sun Aug 24 17:51:08 2014 +1000)
* 08b088c - Added method to pacticipant_service to find potentially duplicated pacticipants (Beth, Sat Aug 23 08:32:34 2014 +
* 24e8d5d - Adding support for creating a pacticipant through the API (as distinct from it being auto created by publishing a
* dc4d4aa - Set DB timezone to UTC. (Beth, Thu Aug 21 17:30:41 2014 +1000)
* 19693fa - Added pact metadata to HTML view (Beth, Thu Aug 21 17:30:23 2014 +1000)

#### 1.1.0 (2014-08-21)

* d25395b - Fixed pacts failing to publish because of too deeply nested JSON (Beth, Tue Aug 19 11:13:02 2014 +1000)
* 9288c98 - Saving password in Base64 just so it is not plain text. WIP (Beth, Tue Aug 19 09:14:53 2014 +1000)
* 6a40151 - Added username and password to webhook request (Beth, Mon Aug 18 22:02:48 2014 +1000)
* 6eb0d70 - Added mouseover for relationship paths (Beth, Fri Aug 15 15:38:56 2014 +1000)
* 8e916fc - Added clickable relationship links (Beth, Fri Aug 15 11:37:57 2014 +1000)
* 7fc6418 - Added webhook HAL documentation. (Beth, Tue Aug 12 17:17:08 2014 +1000)
* 434fbe8 - Added useful rels to help navigate between webhook resources. (Beth, Tue Aug 12 09:14:08 2014 +1000)
* 959675b - Adding description to webhooks link (Beth, Mon Aug 11 21:46:39 2014 +1000)
* 9cbf2b1 - Added webhook test execution endpoint. (Beth, Mon Aug 11 21:37:47 2014 +1000)
* 6bdfd16 - Webhooks belonging to a pacticipant will be deleted when the pacticipant is deleted. (Beth, Mon Aug 11 14:16:50 2014 +1000)
* 27572e2 - WIP - ensuring webhook executes when a pact version is overridden and changed. (Beth, Fri Aug 8 16:59:48 2014 +1000)
* 2469ad5 - Adding webhook DELETE (Beth, Fri Aug 8 16:45:48 2014 +1000)
* 7ae9b59 - Adding code to execte webhook and to detect when pact content has changed (Beth, Fri Aug 8 10:13:16 2014 +1000)
* c8289fb - Adding /webhooks resource (Beth, Thu Aug 7 16:57:27 2014 +1000)
* 2d818ee - Added endpoint to retrieve webhook by UUID (Beth, Thu Aug 7 14:35:04 2014 +1000)
* 25c3866 - Completed web hooks resource. (Beth, Wed Aug 6 11:38:39 2014 +1000)
* a59e46e - Started work on webhooks (Beth, Sat Aug 2 18:12:16 2014 +1000)
* 56d9ae5 - Return 400 error for pacts with invalid JSON (Beth, Sat Aug 2 07:08:39 2014 +1000)
* 884aa06 - Added links from relationship page to group. (Beth, Thu Jul 31 20:05:55 2014 +1000)
* 642570e - Adding group UI endpoint. (Beth, Thu Jul 31 17:36:37 2014 +1000)
* 3609028 - Adding a group resource (Beth, Mon Jul 28 09:11:46 2014 +1000)
* 437df9e - Added created_at and updated_at timestamps to all objects. (Beth, Fri Jul 25 16:53:46 2014 +1000)
* 594f160 - Turning exception showing on (Beth, Fri Jul 25 08:59:57 2014 +1000)
* 7250a51 - Updated to pact 1.3.0 (Beth, Thu Jul 24 12:13:38 2014 +1000)
* 9824247 - Implemented DELETE for pacticipant resource (Beth, Tue Jun 10 17:32:26 2014 +1000)
* 1c65600 - Swapped links and properties order in the HAL browser, because the documents are large, and scrolling to the bottom of the page to click around is annoying. (Beth, Fri Jun 6 10:19:47 2014 +1000)

#### 1.0.0 (2014-06-06)

* ed25adb - Sorting relationships by consumer name, then provider name. (Beth, Wed May 21 15:13:39 2014 +1000)
* 7aae530 - Releasing version 1.0.0.alpha3 (Beth, Mon May 19 15:44:33 2014 +1000)
* 53e24cb - Increased json_content size from text to mediumtext (16MB) (Beth, Mon May 19 15:43:32 2014 +1000)
* 1f65546 - Releasing 1.0.0.alpha2 (Beth, Mon May 19 12:49:42 2014 +1000)
* 3714ab5 - Adding network graph spike files (Beth, Sat May 17 21:12:04 2014 +1000)
* 73e2b81 - Implemented finding latest pact by tag (Beth, Sat May 17 17:56:58 2014 +1000)
* bfa62cc - Changed /pact to /pacts because it is more RESTy (Beth, Sat May 17 12:22:55 2014 +1000)
* 91c8fab - Releasing 1.0.0.alpha1 (Beth, Fri May 9 15:21:13 2014 +1000)
* f497f13 - Made HtmlPactRenderer configurable in case shokkenki want to use the PactBroker ;) (Beth, Fri May 9 14:20:38 2014 +1000)
* 5343019 - Added Relationship UI (Beth, Fri May 9 12:23:30 2014 +1000)
* f7270a6 - Added HTML rendering of latest pact. Added /relationships CSV endpoint. (Beth, Thu May 8 16:17:52 2014 +1000)
* 264e16b - Created nice interface for making a pact_broker instance (Beth, Sat Apr 26 16:43:07 2014 +1000)
* 8001792 - Added HAL browser (Beth, Wed Apr 23 13:31:25 2014 +1000)
* 8c94d1f - Creating example app (Beth, Wed Apr 23 13:06:40 2014 +1000)


#### 0.0.10 (2014-06-06)

  * 24daeea - Added task to delete pacticipant (bethesque Tue May 20 11:59:10 2014 +1000)
  * 53e24cb - Increased json_content size from text to mediumtext (16MB) (bethesque Mon May 19 15:43:32 2014 +1000)
  * 73e2b81 - Implemented finding latest pact by tag (bethesque Sat May 17 17:56:58 2014 +1000)
  * bfa62cc - Changed /pact to /pacts because it is more RESTy (bethesque Sat May 17 12:22:55 2014 +1000)
  * a7a8e0d - Upgraded padrino (bethesque Sat May 17 12:20:57 2014 +1000)
  * 94c7c38 - Setting gem versions in gemspec (bethesque Fri May 9 15:22:37 2014 +1000)
  * f497f13 - Made HtmlPactRenderer configurable in case shokkenki want to use the PactBroker ;) (bethesque Fri May 9 14:20:38 2014 +1000)
  * 1d35da4 - Added sort to relationships list (bethesque Fri May 9 13:56:55 2014 +1000)
  * 000f8a6 - Added HAL Browser link (bethesque Fri May 9 13:39:56 2014 +1000)
  * 85e0a1d - Redirecting index to relationships page (bethesque Fri May 9 13:15:55 2014 +1000)
  * 5343019 - Added Relationship UI (bethesque Fri May 9 12:23:30 2014 +1000)
  * f7270a6 - Added HTML rendering of latest pact. (bethesque Thu May 8 16:17:52 2014 +1000)

#### 0.0.10 (2014-03-24)

* 7aee2ae - Implemented version tagging (bethesque 2 days ago)
* cc78f92 - Added 'latest' pact url to pact representation in the 'latest pacts' response (bethesque 2 days ago)

#### 0.0.9 (2014-02-27)

* d07f4b7 - Using default gem publish tasks (bethesque 4 weeks ago)
* d60b7ee - Comment (bethesque 7 weeks ago)
* 836347c - Using local pacts (bethesque 7 weeks ago)
* a2cb2bb - Fixed bug querying mysql DB, rather than sqlite (bethesque 7 weeks ago)
* 9d5f83b - Using the to_json options to pass in the base_url instead of the nasty hack. (bethesque 4 months ago)
* adb6148 - Changed 'last' to 'latest' (bethesque 4 months ago)

#### 0.0.8 (2013-11-18)

* 6022baa - Changed name to title in list pacticipants response (bethesque 7 hours ago)
* 13fde52 - Moving resources module under the Api module. (bethesque 8 hours ago)
* f52c572 - Added HAL index (bethesque 8 hours ago)

#### 0.0.7 (2013-11-15)

* 7984d86 - Added title to each item in the pacts/latest links array (bethesque 83 seconds ago)

#### 0.0.6 (2013-11-15)

* 021faae - Refactoring resources to DRY out code (bethesque 18 hours ago)
* bab0367 - Cleaning up the base_url setting hack. (bethesque 19 hours ago)
* f6df613 - Renamed representors to decorators (bethesque 19 hours ago)
* 3e89c20 - Created BaseDecorator (bethesque 19 hours ago)
* e5c3f88 - Changing from representors to decorators (bethesque 19 hours ago)
* b2eeb6f - Added back resource_exists? implementation in pacticipant resource - accidental deletion. (bethesque 19 hours ago)
* 1962a05 - Ever so slightly less hacky way of handling PATCH (bethesque 21 hours ago)
* 587e9c1 - First go at trying to use a dynamic base URL - to be continued (bethesque 2 days ago)
* ab9c185 - Including URLs for the dynamically calculated latest pact, not the hard link to the latest pact. (bethesque 2 days ago)
* 5621e41 - Beginning change from Roar Representor to Decoractor. Updating to new 'latest pact' URL (bethesque 2 days ago)
* d1bd995 - Adding missing PactBroker::Logging require (bethesque 2 days ago)


#### 0.0.5 (2013-11-13)

* 2cf987c - Added data migration to script which adds order column (bethesque 56 minutes ago)
* 9c709a9 - Changing queries to use new order column. (bethesque 61 minutes ago)
* 173f231 - Renaming var (bethesque 65 minutes ago)
* f9be93d - Renamed SortVersions to OrderVersions (bethesque 66 minutes ago)
* ca6e479 - Added SortVersions as an after version save hook (bethesque 69 minutes ago)
* 23cd1a3 - Adding order column to version table (bethesque 11 hours ago)
* c504e5f - Fixing application/json+hal to application/hal+json (bethesque 2 days ago)
* 1d24b9b - Removing old sinatra API (bethesque 2 days ago)
* fd1832c - WIP. Converting to use Webmachine (bethesque 2 days ago)
* 0b096a4 - Redoing the the URLs yet again (bethesque 3 days ago)
* 0934d89 - Implementing list latest pacts (bethesque 3 days ago)
* ed2d354 - Changed one_to_one associations to many_to_one (bethesque 4 days ago)
* 28de0ea - WIP implementing pacts/latest. (bethesque 6 days ago)
* 1cd36e6 - Changing to new /pacts/latest URL format (bethesque 6 days ago)
* 54f8fc3 - Writing underlying code to find the latest pact for each consumer/provider pair. (bethesque 6 days ago)
