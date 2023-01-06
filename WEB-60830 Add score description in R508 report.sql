--------RC Starts --------
GO
DECLARE @Code VARCHAR(20)
SET @Code='R508'

UPDATE dbo.RefReport
SET Description='<b>Objective:</b> The report will provide the detailed information of all screening alerts in the period defined using the From date & To date<br />  
				<b>Specification:</b> "The user will be able to extract the output on the following basis: <br />  
				<ol type="a">       <li>Case ID: This denotes the ID for the created cases</li>    
									<li>Case Type: The value here will be either be:</li>
									<ol type="1">       <li>Initial Screening - The screening performed for a customer for the first time within the TrackWizz system</li>    
														<li>Continous Screening - The screening performed when there is a customer / related party data has been updated</li>   
														<li>Watchlist Added - Screening performed when a new entry is added to the watchlist</li>   
														<li>Watchlist Updated - Screening performed when any existing record in the watchlist has been updated</li>       </ol>   
									<li>Case creation date: It is the date on which the case was created</li>    
									<li>Closure date: The date when a decision was taken on a case to close it. WIll be blank for open cases</li>    
									<li>Case last modified date: The date when the user last modified the case by adding comments, uploading attachements etc.</li>    
									<li>Case edited by: The name of the user making changes to the case information</li>    
									<li>Final Decision: The finnal decision will either be pending or completed.    The status of pending means that the case has not been closed yet and action is required on the same.   Once the case is approved or rejected, the status will change to accept business or reject business respectively</li>    
									<li>Customer Name: Customer Name whose alert is shown in the report</li>    
									<li>Customer Code: Customer Code of the customer whose alert is displayed</li>    
									<li>Alert ID: This is the unique ID of the alert that TrackWizz generates</li>    
									<li>Alert Decision: This is the decision taken on each alert within each case. It will show match or no match or will show pending depending on the matching status of the customer data</li>       <li>Alert generation date and time: This is the date and time on which the alert was generated</li>   
									<li>Alert closure date: The date on which the alert was closed by adding in comments and taking a decision on the same</li>    
									<li>Alert remarks: The comments added in by the users at the alert level</li>    
									<li>Case remarks: The comments added in by the users at the case level</li>    
									<li>Source unique ID: The ID for each record within the watchlist source</li>   
									<li>Watchlist Name: The name of each record within the watchlist source</li>    
									<li>Watchlist Category: The watchlist screening category </li>    
									<li>Watchlist Sub Category: The watchlist screening sub-category</li>    
									<li>Final Decision By: The ID of the TrackWizz user who takes the final decison</li>    
									<li>Alert Ageing: It denotes the TAT in days for closing the case</li>    
									<li>Source System Name : As passed from source</li>    
									<li>Source system customer code : As passed from source.</li>    
									<li>PEP : It will display the case level PEP decision.</li>    
									<li>Alert TAT : It will display the alerts that are breached the TAT.</li>    
									<li>Source : The watchlist screening source.</li>    
									<li>WatchList Keyword: The keywords against which the screening to be performed.</li>    
									<li>Primary Match: This will show in which activity the match has found.</li>   
									<li>Match Type: The value here will be either be:</li>    
									<ol type = "1">       <li> Probable - All the matches other than ID based matches</li>     
														  <li> Confirmed - All ID based matches like Passport, PAN, DIN, CIN, Driving License</li>       </ol>    
									<li>Product Acc Type No Relation: This shows the account type and account number of the client as well as its role in the account.</li>    
									<li>Matrix Name: The name of the matrix through which the alert is generated.</li>
									<li>Score: Contains the Score of the Screening Alert that is generated.</li>
									<li>Workflow Step: This will tell us that on which workflow step the case of the alert is present</li>    
									<li>Customer Type: This will tell us the type of the customer</li>   
									<li>Watchlist Type: This will tell us the type of the watchlist</li>    
									<li>Assignee: This will give us the name of the user to whom the case of this alert is assignee to</li>    
									<li>Linked To: This will show us the customers to whom this particular customer is linked to. The linkage will be shown upto 2 level. For Example : A is brother of B and B is sister of C</li>    
									<li>Relation to Customer: This shows the relation of the client with account holder.</li>    </ol>    
									<b>Limitation:</b> The report can be generated for a maximum period of 100 days'
WHERE Code=@Code;
GO
--------Ends---