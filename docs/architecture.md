# Architecture Guide

## Target Structure

```text
lib/
  core/
    constants/
    error/
    router/
    utils/
  features/
    admin/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        views/
        widgets/
    auth/
      data/
      domain/
      presentation/
    order/
      data/
      domain/
      presentation/
    product/
      data/
      domain/
      presentation/
```

## Layer Rules

- `data/` talks to Supabase and knows DTO details.
- `domain/` contains pure Dart entities, repository contracts, and use cases.
- `presentation/` owns widgets and state management only.
- `core/` contains shared cross-feature code, not feature-specific business rules.

## Cart Flow Example

### Data

- `features/order/data/datasources/cart_local_data_source.dart`
  - reads and writes persisted cart state
- `features/order/data/repositories/cart_repository_impl.dart`
  - implements domain contract using local data source

### Domain

- `features/order/domain/entities/cart_item.dart`
  - defines cart item shape without Flutter dependencies
- `features/order/domain/repositories/cart_repository.dart`
  - abstract contract for cart operations
- `features/order/domain/usecases/add_to_cart.dart`
  - validates and adds product to cart
- `features/order/domain/usecases/remove_from_cart.dart`
  - removes item from cart

### Presentation

- `features/order/presentation/providers/cart_provider.dart`
  - coordinates use cases and exposes UI state
- `features/customer/views/cart_view.dart`
  - renders cart screen and delegates actions to provider

## Current Cleanup Applied

- Removed unused barrel files from `lib/`
- Tightened analyzer rules for dead code and unused members
- Kept admin delete flow separated between view, provider, and service
