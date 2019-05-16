/*
 Copyright 2019 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

final class ReactionsMenuViewModel: ReactionsMenuViewModelType {

    // MARK: - Properties

    // MARK: Private
    private let aggregations: MXAggregations
    private let roomId: String
    private let eventId: String

    // MARK: Public

    var isAgreeButtonSelected: Bool = false
    var isDisagreeButtonSelected: Bool = false
    var isLikeButtonSelected: Bool = false
    var isDislikeButtonSelected: Bool = false

    weak var viewDelegate: ReactionsMenuViewModelDelegate?
    weak var coordinatorDelegate: ReactionsMenuViewModelCoordinatorDelegate?

    // MARK: - Setup

    init(aggregations: MXAggregations, roomId: String, eventId: String) {
        self.aggregations = aggregations
        self.roomId = roomId
        self.eventId = eventId

        self.loadData()
        self.listenToDataUpdate()
    }

    // MARK: - Public

    func process(viewAction: ReactionsMenuViewAction) {
        var reaction: ReactionsMenuReaction?
        var newState: Bool?

        switch viewAction {
        case .toggleReaction(let menuReaction):
            reaction = menuReaction

            switch menuReaction {
            case .agree:
                newState = !self.isAgreeButtonSelected
            case .disagree:
                newState = !self.isDisagreeButtonSelected
            case .like:
                newState = !self.isLikeButtonSelected
            case .dislike:
                newState = !self.isDislikeButtonSelected
            }
        }

        guard let theReaction = reaction, let theNewState = newState else {
            return
        }

        self.react(withReaction: theReaction, selected: theNewState)
    }

    // MARK: - Private

    private func resetData() {
        self.isAgreeButtonSelected = false
        self.isDisagreeButtonSelected = false
        self.isLikeButtonSelected = false
        self.isDislikeButtonSelected = false
    }

    private func loadData() {
        guard let reactionCounts = self.aggregations.reactions(onEvent: self.eventId, inRoom: self.roomId) else {
            return
        }

        self.resetData()
        reactionCounts.forEach { (reaction) in
            if let reaction = ReactionsMenuReaction(rawValue: reaction.reaction) {
                switch reaction {
                case .agree:
                    self.isAgreeButtonSelected = true
                case .disagree:
                    self.isDisagreeButtonSelected = true
                case .like:
                    self.isLikeButtonSelected = true
                case .dislike:
                    self.isDislikeButtonSelected = true
                }
            }
        }

        self.viewDelegate?.reactionsMenuViewModelDidUpdate(self)
    }

    private func listenToDataUpdate() {
        self.aggregations.listenToReactionCountUpdate(inRoom: self.roomId) { [weak self] (changes) in

            guard let sself = self else {
                return
            }

            if changes[sself.eventId] != nil {
                sself.loadData()
            }
        }
    }

    private func react(withReaction reaction: ReactionsMenuReaction, selected: Bool) {
        if selected {
            self.aggregations.sendReaction(reaction.rawValue, toEvent: self.eventId, inRoom: self.roomId, success: {_ in

            }, failure: {(error) in
                print("[ReactionsMenuViewModel] react: Error: \(error)")
            })
        } else {
            // TODO
        }

        self.fakeToggleReaction(reaction: reaction)
    }

    // TODO: to remove
    private func fakeToggleReaction(reaction: ReactionsMenuReaction) {
        switch reaction {
        case .agree:
            isAgreeButtonSelected = !isDislikeButtonSelected
        case .disagree:
            isDisagreeButtonSelected = !isDisagreeButtonSelected
        case .like:
            isLikeButtonSelected = !isLikeButtonSelected
        case .dislike:
            isDislikeButtonSelected = !isDislikeButtonSelected
        }

        self.viewDelegate?.reactionsMenuViewModelDidUpdate(self)
    }

}
