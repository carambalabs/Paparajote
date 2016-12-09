import Foundation
import NSURL_QueryDictionary

public struct SoundCloudProvider: OAuth2Provider {

    // MARK: - Attributes

    private let clientId: String //client_id
    private let clientSecret: String //client_secret
    private let redirectUri: String //redirect_uri
    private let responseType: String = "code" //response_type
    private let scope: String = "*" //scope
    private let display: String = "popup" //display
    private let state: String //state

    // MARK: - Init

    public init(clientId: String, clientSecret: String, redirectUri: String, state: String = String.random()) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
        self.state = state
    }

    // MARK: - Oauth2Provider

    public var authorization: Authorization {
        get {
            return { () -> URL in
                return NSURL(string: "https://soundcloud.com/connect")!
                    .uq_URL(byAppendingQueryDictionary: [
                        "client_id": self.clientId,
                        "redirect_uri": self.redirectUri,
                        "response_type": self.responseType,
                        "scope": self.scope,
                        "display": self.display,
                        "state": self.state
                    ]) as URL
            }
        }
    }

    public var authentication: Authentication {
        get {
            return { url -> URLRequest? in
                if !url.absoluteString.contains(self.redirectUri) { return nil }
                guard let code = (url as NSURL).uq_queryDictionary()["code"] as? String,
                    let state = (url as NSURL).uq_queryDictionary()["state"] as? String else { return nil }
                if state != self.state { return nil }
                let authenticationUrl: URL = NSURL(string: "https://api.soundcloud.com/oauth2/token")!
                    .uq_URL(byAppendingQueryDictionary: [
                        "client_id" : self.clientId,
                        "client_secret": self.clientSecret,
                        "code": code,
                        "redirect_uri": self.redirectUri,
                        "grant_type": "authorization_code"
                        ]) as URL
                let request = NSMutableURLRequest()
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = "POST"
                request.url = authenticationUrl
                return request.copy() as? URLRequest
            }
        }
    }

    public var sessionAdapter: SessionAdapter = { (data,  _) -> OAuth2Session? in
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: String] else { return nil }
        return dictionary["access_token"].map {OAuth2Session(accessToken: $0, refreshToken: nil)}
    }

}
