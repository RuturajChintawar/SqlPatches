--RC WEB-72307-START
UPDATE ref
SET ref.[Name] = 'Status & Summary of Alert generation / Case manager activity / Pending / To be reported Alerts',
ref.EmailSubject = 'Summary of “Alert generation / Case manager activity / Pending Alerts” on <SystemDate>',
ref.EmailBody = 'Dear Sir/Madam,<br/>

The Job J1455 Status Email for Alert generation of Composite Job <JobCode> <IsAddedOn> <AddedOn> has run successfully as on Run Date <SystemDate><br/>

1.Below is the summary of Composite Job: <br/>

<SuccessStatusTable><br/>

2.Case manager activity(AML) for date <SystemDate>: <br/>

<CaseManagerActivityTable><br/>

<table>  <tr>  <th colspan=2> How to read the table above </th>  </tr>  
        <tr>  <th>Opening :</th>  <td> Opening Balance</td>  </tr>   
        <tr>  <th> New Alloted:</th>  <td>Assigned to that person (new or old)</td>  </tr>   
        <tr>  <th> Viewed:</th>  <td>Unique cases were viewed</td>  </tr>   
        <tr>  <th>Acted:</th>  <td>Did anything other than view.</td>  </tr>   
        <tr>  <th>Assigned:</th> <td>Assigned to someone else.</td>  </tr>   
        <tr>  <th>StatusChange:</th> <td>Case Status Change.</td>  </tr>   
        <tr>  <th>Closed:</th> <td>Cases closed</td>  </tr>    
        <tr>  <th>To be reported / Reported:</th> <td>case where the status changed to “To be reported” or    “Reported”</td>  </tr>   
        <tr>  <th> Final Balance: </th>  <td>Outstanding cases</td>  </tr> </table> 

3.Consolidated email for pending/ to be reported alerts of Trackwizz For X no. of days. <br/>
<AlertTables> <br>

Instance Name : <InstanceName> / Version : <Version><br />

Do not reply to this email as this is system generated.<br />Thanks, <br />TrackWizz System.'
FROM dbo.RefEmailTemplate ref
WHERE ref.Code ='E1948'
--RC WEB-72307-END
