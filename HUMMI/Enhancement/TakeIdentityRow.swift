//
//  TakeIdentityRow.swift
//  HUMMI
//
//  Two chips naming the character and space applied to a take, each with
//  its own small artwork — so the save screen shows what was made instead
//  of leaving the space empty.
//

import SwiftUI

struct TakeIdentityRow: View {
    let character: CharacterFilter
    let space: SpaceFilter

    var body: some View {
        HStack(spacing: Spacing.s) {
            chip(label: character.name) {
                OrbView(palette: character.orb, seed: character.id, energy: 0.4, diameter: 24)
            }
            chip(label: space.name) {
                SpaceEmblem(palette: space.tile, decay: space.decay, isActive: false, size: 22)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(character.name) voice in the \(space.name)")
    }

    private func chip<Art: View>(label: String, @ViewBuilder art: () -> Art) -> some View {
        HStack(spacing: Spacing.xs) {
            art().frame(width: 26, height: 26)
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.ink.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xs)
        .background(Brand.ink.opacity(0.05), in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.ink.opacity(0.08), lineWidth: 1))
    }
}
